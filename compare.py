import cv2
import numpy as np
from skimage.metrics import peak_signal_noise_ratio as psnr
from skimage.metrics import structural_similarity as ssim
import matplotlib.pyplot as plt

# Đọc file output từ Verilog
try:
    with open('pic_output.txt', 'r') as f:
        # Đọc kích thước
        first_line = f.readline().strip().split()
        height = int(first_line[0])
        width = int(first_line[1])
        
        # Đọc dữ liệu pixel
        verilog_output = np.zeros((height, width), dtype=np.uint8)
        for i in range(height):
            for j in range(width):
                pixel_value = int(f.readline().strip())
                verilog_output[i, j] = pixel_value
    
    print('Đã đọc file pic_output.txt thành công')
except FileNotFoundError:
    print('Lỗi: Không tìm thấy file pic_output.txt')
    exit(1)

# Lưu ảnh kết quả
cv2.imwrite('verilog_filtered.png', verilog_output)
print('Đã lưu ảnh kết quả: verilog_filtered.png')

# Đọc ảnh gốc để so sánh
original = cv2.imread('input_gray.png', cv2.IMREAD_GRAYSCALE)

# So sánh với kết quả Python/OpenCV
python_filtered = cv2.imread('python_filtered.png', cv2.IMREAD_GRAYSCALE)
opencv_filtered = cv2.imread('opencv_filtered.png', cv2.IMREAD_GRAYSCALE)

# Tính PSNR và SSIM
print('\n=== Đánh giá chất lượng ===')

# So sánh Verilog output với Python output
psnr_python = psnr(python_filtered, verilog_output)
ssim_python = ssim(python_filtered, verilog_output)

print(f'PSNR (Verilog vs Python): {psnr_python:.2f} dB')
print(f'SSIM (Verilog vs Python): {ssim_python:.4f}')

# So sánh Verilog output với OpenCV output
psnr_opencv = psnr(opencv_filtered, verilog_output)
ssim_opencv = ssim(opencv_filtered, verilog_output)

print(f'\nPSNR (Verilog vs OpenCV): {psnr_opencv:.2f} dB')
print(f'SSIM (Verilog vs OpenCV): {ssim_opencv:.4f}')

# So sánh với ảnh gốc
psnr_original = psnr(original, verilog_output)
ssim_original = ssim(original, verilog_output)

print(f'\nSo với ảnh gốc:')
print(f'PSNR (Filtered vs Original): {psnr_original:.2f} dB')
print(f'SSIM (Filtered vs Original): {ssim_original:.4f}')

# Tính sai khác
diff_python = np.abs(verilog_output.astype(int) - python_filtered.astype(int))
diff_opencv = np.abs(verilog_output.astype(int) - opencv_filtered.astype(int))

max_diff_python = np.max(diff_python)
mean_diff_python = np.mean(diff_python)

max_diff_opencv = np.max(diff_opencv)
mean_diff_opencv = np.mean(diff_opencv)

print(f'\nSai khác giữa Verilog và Python:')
print(f'Sai khác tối đa: {max_diff_python}')
print(f'Sai khác trung bình: {mean_diff_python:.4f}')

print(f'\nSai khác giữa Verilog và OpenCV:')
print(f'Sai khác tối đa: {max_diff_opencv}')
print(f'Sai khác trung bình: {mean_diff_opencv:.4f}')

if max_diff_opencv == 0:
    print('\n✓ Kết quả Verilog hoàn toàn giống OpenCV!')
elif mean_diff_opencv < 1:
    print('\n✓ Kết quả Verilog rất tốt (sai khác nhỏ)!')
else:
    print('\n⚠ Có sai khác đáng kể, cần kiểm tra lại code Verilog')

# Hiển thị kết quả
fig, axes = plt.subplots(2, 3, figsize=(15, 10))

# Hàng 1: Ảnh
axes[0, 0].imshow(original, cmap='gray')
axes[0, 0].set_title('Ảnh gốc')
axes[0, 0].axis('off')

axes[0, 1].imshow(opencv_filtered, cmap='gray')
axes[0, 1].set_title('OpenCV Median Filter')
axes[0, 1].axis('off')

axes[0, 2].imshow(verilog_output, cmap='gray')
axes[0, 2].set_title('Verilog Median Filter')
axes[0, 2].axis('off')

# Hàng 2: Histogram
axes[1, 0].hist(original.ravel(), bins=256, range=[0, 256], color='blue', alpha=0.7)
axes[1, 0].set_title('Histogram - Ảnh gốc')
axes[1, 0].set_xlabel('Pixel Value')
axes[1, 0].set_ylabel('Frequency')

axes[1, 1].hist(opencv_filtered.ravel(), bins=256, range=[0, 256], color='green', alpha=0.7)
axes[1, 1].set_title('Histogram - OpenCV')
axes[1, 1].set_xlabel('Pixel Value')
axes[1, 1].set_ylabel('Frequency')

axes[1, 2].hist(verilog_output.ravel(), bins=256, range=[0, 256], color='red', alpha=0.7)
axes[1, 2].set_title('Histogram - Verilog')
axes[1, 2].set_xlabel('Pixel Value')
axes[1, 2].set_ylabel('Frequency')

plt.tight_layout()
plt.savefig('comparison_result.png', dpi=150, bbox_inches='tight')
plt.show()

print('\n✓ Đã lưu biểu đồ so sánh: comparison_result.png')

# Hiển thị sai khác
fig, axes = plt.subplots(1, 2, figsize=(12, 5))

im1 = axes[0].imshow(diff_opencv, cmap='hot')
axes[0].set_title('Sai khác (Verilog - OpenCV)')
axes[0].axis('off')
plt.colorbar(im1, ax=axes[0])

im2 = axes[1].imshow(diff_python, cmap='hot')
axes[1].set_title('Sai khác (Verilog - Python)')
axes[1].axis('off')
plt.colorbar(im2, ax=axes[1])

plt.tight_layout()
plt.savefig('difference_map.png', dpi=150, bbox_inches='tight')
plt.show()

print('✓ Đã lưu bản đồ sai khác: difference_map.png')