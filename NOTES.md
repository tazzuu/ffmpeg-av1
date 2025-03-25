some extra helpful commands

```bash
docker run --rm -ti -v $PWD:$PWD --workdir $PWD ffmpeg-av1:7.1.1 ffmpeg -i input.mkv -f ffmetadata meta.txt
docker run --rm -ti -v $PWD:$PWD --workdir $PWD ffmpeg-av1:7.1.1 ffprobe -i input.mkv
```