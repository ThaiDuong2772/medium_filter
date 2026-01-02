import cv2
import numpy as np
from scipy.ndimage import median_filter

# Đọc ảnh và chuyển sang grayscale
img = cv2.imread('baitap1_nhieu.jpg')  # Thay tên file ảnh của bạn
gray_img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Lưu ảnh grayscale
cv2.imwrite('input_gray.png', gray_img)

# Lấy kích thước ảnh
height, width = gray_img.shape

# Ghi ra file txt để Verilog đọc
with open('pic_input.txt', 'w') as f:
    # Dòng đầu: chiều cao và chiều rộng
    f.write(f'{height} {width}\n')
    
    # Ghi từng giá trị pixel (0-255)
    for i in range(height):
        for j in range(width):
            f.write(f'{gray_img[i, j]}\n')

print(f'Đã tạo file pic_input.txt với kích thước: {height}x{width}')

# Test median filter bằng Python để so sánh
python_filtered = median_filter(gray_img, size=3)
cv2.imwrite('python_filtered.png', python_filtered)

# Hoặc dùng OpenCV
opencv_filtered = cv2.medianBlur(gray_img, 3)
cv2.imwrite('opencv_filtered.png', opencv_filtered)

print('Đã tạo ảnh lọc chuẩn bằng Python/OpenCV để so sánh')