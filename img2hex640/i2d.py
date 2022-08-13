from PIL import Image
import numpy as np
#pip install pillow numpy

#640*480
# 读取图片
img_cnt=0
while img_cnt<=9:
	im = Image.open(str(img_cnt)+".png")
	# 显示图片
	#im.show() 
	im = im.convert("L") 
	data = im.getdata()
	data = np.matrix(data)
	# 变换成一维矩阵
	data = np.array(data).reshape(640*480)

	obj=open('./obj'+str(img_cnt)+'.txt','w+')#创建输出文件
	i=0;

	while i<len(data):#8b转为hex有符号数
		hex_str=str(hex(data[i])[2:])
		if len(hex_str)==1:
			hex_str=('0'+hex_str)
		else:
			hex_str=hex_str
		obj.write(hex_str+"\n")
		i=i+1
	obj.close()
	img_cnt=img_cnt+1
