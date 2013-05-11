# CUDA_INCLUDEPATH=/usr/local/cuda/include
# CUDA_LIBPATH=/usr/local/cuda/lib

CC = g++
LDFLAGS = -I/usr/local/include/opencv -lm -lopencv_core -lopencv_highgui -lopencv_video -lboost_filesystem-mt -lboost_date_time-mt -lboost_system-mt


all:
	$(CC) testconfig.h main.cpp -o nlm-standard $(LDFLAGS)

test:
	./nlm-standard '../../../data/images/comedian.png'