n2 = ['510613', '358', '84', '40702', '4373582', '2', '0', '1584']

def doBlink(item):
  if item == "0":
    return "1"
  else:
    length = len(item)
    if length % 2 == 0:
      length //= 2
      return [item[:length], item[length:].lstrip("0") or "0"]
    else:
      return str(int(item) * 2024)

lookup = {}

def blink(num, count, remaining):
  if num not in lookup:
    lookup[num] = {}
  
  cached = lookup[num].get(remaining)
  if cached is not None:
    return cached

  item = doBlink(num)
  if remaining == 0:
    n = 2 if isinstance(item, list) else 1
    lookup[num][remaining] = n
    return n

  if isinstance(item, list):
    child = blink(item[0], count, remaining - 1) + blink(item[1], count, remaining - 1)
  else:
    child = blink(item, count, remaining - 1)

  lookup[num][remaining] = child
  return child + count

for i in range(75):
  print(i + 1, sum([blink(x, 0, i) for x in n2]))