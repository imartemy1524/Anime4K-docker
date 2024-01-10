#!/usr/local/bin/python
import argparse
import os
import sys

SHADERS = {
    'a': "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_VL.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl",
    'b': "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_Soft_VL.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl",
    'c': "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl",
    'a+a': "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_VL.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl:~~/shaders/Anime4K_Restore_CNN_M.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl",
    'b+b': "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_Soft_VL.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Restore_CNN_Soft_M.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl",
    'c+a': "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Restore_CNN_M.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"
}

parser = argparse.ArgumentParser(
    prog='Anime4KDocker',
    description='This program converts anime to 4K',
    epilog='Usage: python run.py -i ./input.mp4 ./output.mp4 -w=4000 -h=2000',
    add_help=False
)
parser.add_argument('output')  # positional argument
parser.add_argument('-i', '--input', dest='input')  # option that takes a value
parser.add_argument('-w', '--width', type=int, default=3840, dest='width')
parser.add_argument('-h', '--height', type=int, default=2160, dest='height')
parser.add_argument('--no-audio', action=argparse.BooleanOptionalAction, dest="no_audio", default=False)
parser.add_argument(
    '-s', '--shaders',
    default="a+a"
)
parser.add_argument('-c', '--codec', default='mpeg4')

args = parser.parse_args()
out = args.output
input = args.input
width = args.width
height = args.height
shaders = args.shaders
if len(shaders) <= 3:
    shaders = SHADERS.get(shaders.lower())
    if not shaders:
        print(f"shader {shaders} not found!", file=sys.stderr)
        exit(1)
codec = args.codec

my_args = [
    'mpv',
    f'--glsl-shaders="{shaders}"',
    f'--o="{out}"',
    '--interpolation',
    '--msg-level=all=debug',
    f'--ovc={codec}',
    '--ovcopts=q:v=2',
    '--scale=ewa_lanczossharp',
    '--cscale=ewa_lanczossharp',
    input,
    f'-vf=gpu="w={width}:h={height}:api=vulkan,format=yuv420p"'
]

if args.no_audio: my_args.append('--no-audio')
os.system(' '.join(my_args))
