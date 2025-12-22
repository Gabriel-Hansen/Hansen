/*
 * Hansen Accelerator API
 * Version 1.0.0
 *
 * This header defines the stable public interface for the Hansen Accelerator.
 * Drivers and Applications should link against libraries implementing this
 * interface.
 */

#ifndef HANSEN_API_H
#define HANSEN_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// --- Versioning ---
#define HANSEN_API_VERSION_MAJOR 1
#define HANSEN_API_VERSION_MINOR 0
#define HANSEN_API_VERSION_PATCH 0

// --- Error Codes ---
typedef enum {
  HANSEN_SUCCESS = 0,
  HANSEN_ERR_DEVICE_NOT_FOUND = -1,
  HANSEN_ERR_OUT_OF_MEMORY = -2,
  HANSEN_ERR_INVALID_ARGUMENT = -3,
  HANSEN_ERR_TIMEOUT = -4,
  HANSEN_ERR_INTERNAL = -5
} hansen_result_t;

// --- Types ---
// Opaque handle to a device context
typedef struct hansen_device_t *hansen_device_handle_t;

// --- Device Management ---

/**
 * @brief Initialize the library and enumerate devices.
 *
 * @param device_id Index of the device to open (0 for first device).
 * @param handle_out Pointer to receive the device handle.
 * @return HANSEN_SUCCESS on success.
 */
hansen_result_t hansen_open(int device_id, hansen_device_handle_t *handle_out);

/**
 * @brief Close the device and release resources.
 *
 * @param handle The device handle to close.
 */
void hansen_close(hansen_device_handle_t handle);

// --- Memory Management ---

/**
 * @brief Copy data from Host to Device memory (DMA).
 *
 * @param handle Device handle.
 * @param dst_addr Destination address in device memory.
 * @param src_data Pointer to host data.
 * @param size_bytes Number of bytes to copy.
 * @return HANSEN_SUCCESS, HANSEN_ERR_INVALID_ARGUMENT if out of bounds.
 */
hansen_result_t hansen_memcpy_to_device(hansen_device_handle_t handle,
                                        uint32_t dst_addr, const void *src_data,
                                        size_t size_bytes);

/**
 * @brief Copy data from Device (DMA) to Host memory.
 *
 * @param handle Device handle.
 * @param dst_data Pointer to host buffer.
 * @param src_addr Source address in device memory.
 * @param size_bytes Number of bytes to copy.
 */
hansen_result_t hansen_memcpy_from_device(hansen_device_handle_t handle,
                                          void *dst_data, uint32_t src_addr,
                                          size_t size_bytes);

// --- Execution ---

/**
 * @brief Submit a binary kernel for execution.
 *
 * @param handle Device handle.
 * @param instructions Pointer to binary instruction buffer.
 * @param count Number of 32-bit instructions.
 * @return HANSEN_SUCCESS.
 */
hansen_result_t hansen_launch_kernel(hansen_device_handle_t handle,
                                     const uint32_t *instructions,
                                     size_t count);

/**
 * @brief Wait for the current kernel to finish execution.
 *
 * @param handle Device handle.
 * @param timeout_ms Max time to wait in milliseconds.
 * @return HANSEN_SUCCESS or HANSEN_ERR_TIMEOUT.
 */
hansen_result_t hansen_wait_idle(hansen_device_handle_t handle,
                                 uint32_t timeout_ms);

#ifdef __cplusplus
}
#endif

#endif // HANSEN_API_H
