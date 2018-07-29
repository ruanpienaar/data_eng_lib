# Gameanalytics data engineer exercise

## Summury

Erlang was my choice of technology to solve this problem, since it was less time consuming for me to write a solution. I bet there are other considerations to make when choosing the appropriate language/technology.

## Running the example
( I couldn't get zcat to work for me, so i used gunzip -c FILE )

### Help
```
./_build/default/bin/data_eng_lib -h
```

### Standard IO example

```
make && time gunzip -c data/events.json.gz | ./_build/default/bin/data_eng_lib | python -m json.tool

```

### Files example ( uncompressed, for now... )
```
make && time ./_build/default/bin/data_eng_lib filename1, filename2 | python -m
```