# Anime4K docker image

This is a docker image, which contains [fork](https://github.com/imartemy1524/mpv) of [mpv player](https://github.com/mpv-player/mpv) (build with vulkan shader processing),
[anime4k](https://github.com/bloc97/Anime4K) shaders, NVIDIA drivers and python3.10.

To use it, you are required to have NVIDIA GPU on your machine and working drivers.


### HowTo:
1) To start the conversion, first build the dockerimage:
```shell
docker compose build
``` 
or download it from the dockerhub:
```shell
docker pull imartemy1524/anime4k:4.0
```

2) Prepare video file, place it into the root directory of the project, for example, **abc.mp4** and edit the `volumes` in [docker-compose.yaml](docker-compose.yaml) file: replace `./test.mkv:/home/test.mkv` with `./abc.mp4:/home/abc.mp4`


3) In the same file edit command: replace **test.mkv** with your filename (in our case **abc.mp4**) and specify needed arguments:


### Arguments
#### anime4k file can run with next arguments:

- `output` - pass the output file as required argument. Recommended to pass path to [out](out) directory, because it is mounted to real directory on this device (for example, `out/test.mkv`).
- `-i` (`--input`) - input video file
- `-w` (`--width`) - output width of resized video (default **3840**)
- `-h` (`--height`) - output height of resized video (default **2160**)
- `-c` (`--codec`) - encoder of result video file, which you can list using `ffmpeg -encoders` (default: `mpeg4`).
<br> **Warning**: some of the codecs may not work, or work really slow because inside docker gpu is virtual, which may impose restrictions.
- `-s` (`--shaders`) - string, contains shaders to apply, possible values: `a`, `b`, `c`, `a+a`, `b+b` (default `A+A`). 
- `--no-audio` - add if you don't want to have audio in output file

For example, command to convert video `abc.mp4` to 8k (**7680x4320**) without audio would be:
`--no-audio -i abc.mp4 out/out.mkv`.


### Remark

You can always modify [run.py](run.py) for your needs and recompile the docker image, if you need more arguments.




# How to run

In widnows you can just run the docker:
```shell
docker compose up
```

In linux, sometimes it is required to have root permissions to access GPU, so the command would be:
```shell
sudo docker compose up
```

 

