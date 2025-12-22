#include "../include/hansen_api.h"
#include <stdio.h>
#include <stdlib.h>

// Mock Implementation for Testing
// In a real build, this would link against libhansen.so
struct hansen_device_t {
  int dummy;
};

hansen_result_t hansen_open(int device_id, hansen_device_handle_t *handle_out) {
  if (!handle_out)
    return HANSEN_ERR_INVALID_ARGUMENT;
  if (device_id < 0)
    return HANSEN_ERR_DEVICE_NOT_FOUND;
  *handle_out = (hansen_device_handle_t)malloc(sizeof(struct hansen_device_t));
  return HANSEN_SUCCESS;
}

void hansen_close(hansen_device_handle_t handle) {
  if (handle)
    free(handle);
}

hansen_result_t hansen_memcpy_to_device(hansen_device_handle_t handle,
                                        uint32_t dst_addr, const void *src_data,
                                        size_t size_bytes) {
  if (!handle || !src_data)
    return HANSEN_ERR_INVALID_ARGUMENT;
  if (dst_addr + size_bytes > 65536)
    return HANSEN_ERR_INVALID_ARGUMENT; // 64KB limit
  return HANSEN_SUCCESS;
}

// Test Suite
int main() {
  printf("--- Hansen API Robustness Test ---\n");

  hansen_device_handle_t dev = NULL;
  hansen_result_t res;

  // Test 1: Open with NULL pointer (Should Fail)
  printf("Test 1: Open(NULL)... ");
  res = hansen_open(0, NULL);
  if (res == HANSEN_ERR_INVALID_ARGUMENT)
    printf("PASS\n");
  else
    printf("FAIL (%d)\n", res);

  // Test 2: Valid Open
  printf("Test 2: Open(0)... ");
  res = hansen_open(0, &dev);
  if (res == HANSEN_SUCCESS && dev != NULL)
    printf("PASS\n");
  else
    printf("FAIL\n");

  // Test 3: Out of Bounds Write (Should Fail)
  printf("Test 3: Buffer Overflow (>64KB)... ");
  uint32_t data = 0;
  res = hansen_memcpy_to_device(dev, 65530, &data, 100); // 65530 + 100 > 65536
  if (res == HANSEN_ERR_INVALID_ARGUMENT)
    printf("PASS\n");
  else
    printf("FAIL\n");

  // Test 4: NULL Data (Should Fail)
  printf("Test 4: Null Data Ptr... ");
  res = hansen_memcpy_to_device(dev, 0, NULL, 4);
  if (res == HANSEN_ERR_INVALID_ARGUMENT)
    printf("PASS\n");
  else
    printf("FAIL\n");

  // Cleanup
  hansen_close(dev);
  return 0;
}
