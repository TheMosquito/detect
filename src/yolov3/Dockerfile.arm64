# Start with the NVIDIA base image
FROM nvcr.io/nvidia/l4t-base:r32.2

# Install build tools
RUN apt-get update && apt-get install -y --no-install-recommends git make g++ python-pip python-setuptools python-dev zlib1g-dev libjpeg-dev

# Download and build darknet
RUN git clone https://github.com/pjreddie/darknet
WORKDIR /
RUN sed -i 's/^GPU=0$/GPU=1/' /darknet/Makefile
RUN make -C /darknet

# Download a set of vertex weight
#RUN cd /darknet; wget https://pjreddie.com/media/files/yolov3.weights
RUN cd /darknet; wget https://pjreddie.com/media/files/yolov3-tiny.weights

# Run darknet to make a prediction
#CMD cd /darknet; ./darknet detect ./cfg/yolov3.cfg ./yolov3.weights ./data/dog.jpg
#CMD cd /darknet; ./darknet detect ./cfg/yolov3-tiny.cfg ./yolov3-tiny.weights ./data/dog.jpg

# Required libraries
RUN pip install wheel
RUN pip install flask requests pillow

# Copy over the logo(s)
COPY o-h.png /
COPY ibm.png /

# Copy over the code
COPY darknet.py /

# Startup the daemon
CMD cd /darknet; python /darknet.py cfg/yolov3-tiny.cfg yolov3-tiny.weights cfg/coco.data

