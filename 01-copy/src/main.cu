#include <cassert>
#include <cuda_runtime.h>

#include <cstdio>
#include <cstdlib>
#include <vector>

#define CUDA_CHECK(call)                                                                           \
  do {                                                                                             \
    cudaError_t err__ = (call);                                                                    \
    if (err__ != cudaSuccess) {                                                                    \
      std::fprintf(stderr, "CUDA error %s:%d: %s\n", __FILE__, __LINE__,                           \
                   cudaGetErrorString(err__));                                                     \
      std::exit(EXIT_FAILURE);                                                                     \
    }                                                                                              \
  } while (0)

// 1. Baseline kernel: 1 thread copies 1 float
__global__ void copy_kernel_baseline(const float *src, float *dst, unsigned long size) {
  int i = blockDim.x * blockIdx.x + threadIdx.x;
  if (i < size) {
    dst[i] = src[i];
  }
}

// 2. Vectorized kernel: 1 thread copies 1 float4 (4 floats, 16 bytes)
__global__ void copy_kernel_vectorized(const float *src, float *dst, unsigned long size) {
  int i = blockDim.x * blockIdx.x + threadIdx.x;
  unsigned long size_f4 = size / 4;
  if (i < size_f4) {
    const float4 *src_f4 = reinterpret_cast<const float4*>(src);
    float4 *dst_f4 = reinterpret_cast<float4*>(dst);
    dst_f4[i] = src_f4[i];
  }
}

// 3. Grid-stride loop kernel: 1 thread copies multiple floats using stride
__global__ void copy_kernel_stride(const float *src, float *dst, unsigned long size) {
  int tid = blockDim.x * blockIdx.x + threadIdx.x;
  int stride = blockDim.x * gridDim.x;
  for (int i = tid; i < size; i += stride) {
    dst[i] = src[i];
  }
}

// 4. Vectorized grid-stride loop kernel: 1 thread copies multiple float4s
__global__ void copy_kernel_vectorized_stride(const float *src, float *dst, unsigned long size) {
  const float4 *src_f4 = reinterpret_cast<const float4*>(src);
  float4 *dst_f4 = reinterpret_cast<float4*>(dst);
  unsigned long size_f4 = size / 4;

  int tid = blockDim.x * blockIdx.x + threadIdx.x;
  int stride = blockDim.x * gridDim.x;
  for (int i = tid; i < size_f4; i += stride) {
    dst_f4[i] = src_f4[i];
  }
}

float run_benchmark(void (*kernel)(const float*, float*, unsigned long), 
                    const float *src_device, float *dst_device, unsigned long size, 
                    int blocks, int threads, const char *name) {
  cudaEvent_t start, stop;
  CUDA_CHECK(cudaEventCreate(&start));
  CUDA_CHECK(cudaEventCreate(&stop));

  // Warmup
  kernel<<<blocks, threads>>>(src_device, dst_device, size);
  CUDA_CHECK(cudaDeviceSynchronize());

  CUDA_CHECK(cudaEventRecord(start));
  int iterations = 100;
  for (int i = 0; i < iterations; ++i) {
    kernel<<<blocks, threads>>>(src_device, dst_device, size);
  }
  CUDA_CHECK(cudaEventRecord(stop));
  CUDA_CHECK(cudaEventSynchronize(stop));

  float milliseconds = 0;
  CUDA_CHECK(cudaEventElapsedTime(&milliseconds, start, stop));
  float avg_ms = milliseconds / iterations;

  // Bandwidth calculation: Read size bytes + Write size bytes
  double bytes = 2.0 * size * sizeof(float);
  double gb_per_sec = (bytes / 1e9) / (avg_ms / 1000.0);

  std::printf("%-30s : %8.3f ms | %8.3f GB/s\n", name, avg_ms, gb_per_sec);

  CUDA_CHECK(cudaEventDestroy(start));
  CUDA_CHECK(cudaEventDestroy(stop));
  return gb_per_sec;
}

int main(int argc, char **argv) {
  const char *binary_name = (argc > 0 && argv[0] != nullptr) ? argv[0] : "01-copy";
  std::printf("%s starting\n", binary_name);

  // Use a larger size for meaningful bandwidth benchmarking (32 million floats = 128 MB)
  const unsigned long SIZE = 1 << 25; 
  std::printf("Benchmark Size: %lu elements (Data size: %.2f MB)\n", SIZE, (double)SIZE * sizeof(float) / 1024.0 / 1024.0);

  float *src_device;
  float *dst_device;

  std::vector<float> src_host(SIZE, 1.0f);
  std::vector<float> dst_host(SIZE, 0.0f);

  CUDA_CHECK(cudaMalloc(&src_device, SIZE * sizeof(float)));
  CUDA_CHECK(cudaMalloc(&dst_device, SIZE * sizeof(float)));

  CUDA_CHECK(cudaMemcpy(src_device, src_host.data(), SIZE * sizeof(float), cudaMemcpyKind::cudaMemcpyHostToDevice));

  int threads = 256;
  int blocks = (SIZE + threads - 1) / threads;

  // For vectorized kernel, we launch fewer threads because each thread processes 4 elements
  int blocks_vectorized = (SIZE / 4 + threads - 1) / threads;

  // For stride kernels, we can limit the grid size
  int stride_blocks = 80; 

  std::printf("\n--- Performance Results ---\n");
  run_benchmark(copy_kernel_baseline, src_device, dst_device, SIZE, blocks, threads, "Baseline");
  run_benchmark(copy_kernel_vectorized, src_device, dst_device, SIZE, blocks_vectorized, threads, "Vectorized (float4)");
  run_benchmark(copy_kernel_stride, src_device, dst_device, SIZE, stride_blocks, threads, "Grid-Stride Loop");
  run_benchmark(copy_kernel_vectorized_stride, src_device, dst_device, SIZE, stride_blocks, threads, "Vectorized Grid-Stride");

  // Verify correctness using the last run
  CUDA_CHECK(cudaMemcpy(dst_host.data(), dst_device, SIZE * sizeof(float), cudaMemcpyKind::cudaMemcpyDeviceToHost));
  for (unsigned long i = 0; i < SIZE; i++) {
    if (dst_host[i] != 1.0f) {
      std::fprintf(stderr, "Verification failed at index %lu: expected 1.0, got %f\n", i, dst_host[i]);
      std::exit(EXIT_FAILURE);
    }
  }
  std::printf("\nVerification successful!\n");

  cudaFree(src_device);
  cudaFree(dst_device);

  return EXIT_SUCCESS;
}
