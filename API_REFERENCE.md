# Hansen API Reference Manual v1.0

This document describes the C Application Programming Interface (API) for the Hansen Accelerator.

---

## 1. Stability Policy
The Hansen API follows **Semantic Versioning 2.0.0**:
- **MAJOR** version increments (1.x -> 2.x) indicate incompatible API changes.
- **MINOR** version increments (1.1 -> 1.2) add functionality in a generic backwards-compatible manner.
- **PATCH** version increments (1.1.1 -> 1.1.2) indicate bug fixes.

**Guarantee**: Binaries compiled against headers 1.x will work with any Driver 1.y where y >= x.

---

## 2. Functions

### Device Management

#### `hansen_open`
```c
hansen_result_t hansen_open(int device_id, hansen_device_handle_t* handle_out);
```
Acquires a context for the accelerator.
- **Returns**: `HANSEN_SUCCESS`, `HANSEN_ERR_DEVICE_NOT_FOUND`.

#### `hansen_close`
```c
void hansen_close(hansen_device_handle_t handle);
```
Releases the device context.

---

### Memory Management

#### `hansen_memcpy_to_device`
```c
hansen_result_t hansen_memcpy_to_device(hansen_device_handle_t handle, uint32_t dst_addr, const void* src_data, size_t size_bytes);
```
Initiates a DMA transfer from Host to Device.
- **Alignment**: `src_data` should ideally be 4-byte aligned for performance.
- **Bounds Checking**: The driver verifies that `dst_addr + size_bytes` does not exceed device memory (64KB).

---

### Execution Control

#### `hansen_launch_kernel`
```c
hansen_result_t hansen_launch_kernel(hansen_device_handle_t handle, const uint32_t* instructions, size_t count);
```
Loads instructions into the instruction memory and resets the PC to 0. Execution begins immediately (asynchronously).

#### `hansen_wait_idle`
```c
hansen_result_t hansen_wait_idle(hansen_device_handle_t handle, uint32_t timeout_ms);
```
Blocks the calling thread until the accelerator triggers a completion interrupt or the timeout expires.

---

## 3. Error Codes
| Code | Name | Description |
|---|---|---|
| 0 | `HANSEN_SUCCESS` | Operation completed successfully. |
| -1 | `HANSEN_ERR_DEVICE_NOT_FOUND` | No physical device or simulator detected. |
| -3 | `HANSEN_ERR_INVALID_ARGUMENT` | Null pointer or out-of-bounds access. |
| -4 | `HANSEN_ERR_TIMEOUT` | Workload exceeded time limit (Watchdog). |

---
**Note**: This API is designed to be ABI stable. Do not modify the `hansen_device_handle_t` definition userspace.
