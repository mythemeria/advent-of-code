from time import perf_counter_ns
from functools import cache

n2 = [510613, 358, 84, 40702, 4373582, 2, 0, 1584]

@cache
def doBlink(item):
  if not item:
    return 1
  else:
    asStr = f'{item}'
    length = len(asStr)
    if length % 2 == 0:
      length //= 2
      return [int(asStr[:length]), int(asStr[length:].lstrip("0") or 0)]
    else:
      return item * 2024

@cache
def blink(num, remaining):
  item = doBlink(num)
  if remaining == 0:
    n = 2 if isinstance(item, list) else 1
    return n

  if isinstance(item, list):
    child = blink(item[0], remaining - 1) + blink(item[1], remaining - 1)
  else:
    child = blink(item, remaining - 1)

  return child

i = 30
start = perf_counter_ns()
rocks = sum([blink(x, i) for x in n2])
end = perf_counter_ns()

print(f'f({i + 1}) = {rocks} mine: {end - start} ns')
print(blink.cache_info())
print(doBlink.cache_info())