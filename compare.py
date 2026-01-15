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
original = cv2.imread('baitap1_anhgoc.jpg', cv2.IMREAD_GRAYSCALE)

if original is None:
    print('Lỗi: Không tìm thấy file baitap1_anhgoc.jpg')
    exit(1)

# Tính PSNR và SSIM
print('\n=== Đánh giá chất lượng ===')

# So sánh với ảnh gốc
psnr_value = psnr(original, verilog_output)
ssim_value = ssim(original, verilog_output)

print(f'PSNR (Verilog vs Original): {psnr_value:.2f} dB')
print(f'SSIM (Verilog vs Original): {ssim_value:.4f}')

# Tính sai khác
diff = np.abs(verilog_output.astype(int) - original.astype(int))

max_diff = np.max(diff)
mean_diff = np.mean(diff)

print(f'\nSai khác giữa ảnh Verilog và ảnh gốc:')
print(f'Sai khác tối đa: {max_diff}')
print(f'Sai khác trung bình: {mean_diff:.4f}')

# Đánh giá kết quả
if mean_diff < 5:
    print('\n✓ Kết quả rất tốt - median filter đã giảm nhiễu hiệu quả!')
elif mean_diff < 10:
    print('\n✓ Kết quả tốt - có sự khác biệt nhưng vẫn giữ được thông tin!')
else:
    print('\n⚠ Có sai khác đáng kể so với ảnh gốc')

# Hiển thị kết quả
fig, axes = plt.subplots(2, 2, figsize=(12, 10))

# Hàng 1: Ảnh
axes[0, 0].imshow(original, cmap='gray')
axes[0, 0].set_title('Ảnh gốc')
axes[0, 0].axis('off')

axes[0, 1].imshow(verilog_output, cmap='gray')
axes[0, 1].set_title('Verilog Median Filter')
axes[0, 1].axis('off')

# Hàng 2: Histogram
axes[1, 0].hist(original.ravel(), bins=256, range=[0, 256], color='blue', alpha=0.7)
axes[1, 0].set_title('Histogram - Ảnh gốc')
axes[1, 0].set_xlabel('Pixel Value')
axes[1, 0].set_ylabel('Frequency')

axes[1, 1].hist(verilog_output.ravel(), bins=256, range=[0, 256], color='red', alpha=0.7)
axes[1, 1].set_title('Histogram - Verilog')
axes[1, 1].set_xlabel('Pixel Value')
axes[1, 1].set_ylabel('Frequency')

plt.tight_layout()
plt.savefig('comparison_result.png', dpi=150, bbox_inches='tight')
plt.show()

print('\n✓ Đã lưu biểu đồ so sánh: comparison_result.png')

# Hiển thị sai khác
fig, axes = plt.subplots(1, 2, figsize=(12, 5))

im1 = axes[0].imshow(diff, cmap='hot')
axes[0].set_title('Bản đồ sai khác (|Verilog - Original|)')
axes[0].axis('off')
plt.colorbar(im1, ax=axes[0], label='Giá trị sai khác')

# Hiển thị chi tiết vùng có sai khác lớn
diff_highlighted = original.copy()
diff_highlighted[diff > 10] = 255  # Đánh dấu vùng sai khác > 10
axes[1].imshow(diff_highlighted, cmap='gray')
axes[1].set_title('Vùng sai khác lớn (>10)')
axes[1].axis('off')

plt.tight_layout()
plt.savefig('difference_map.png', dpi=150, bbox_inches='tight')
plt.show()

print('✓ Đã lưu bản đồ sai khác: difference_map.png')