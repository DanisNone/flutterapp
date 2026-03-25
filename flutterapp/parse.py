file = open("q.txt", "r", encoding="utf8")

for line in file:
    line = line.strip()
    if not line:
        continue
    assert line.startswith("<file_name>"), line
    name = line.removeprefix("<file_name>").removesuffix("</file_name>")
    line = next(file).strip()
    assert line.startswith("```dart")
    data = []
    for line in file:
        if line.strip() == "```":
            break
        data.append(line)
    
    with open(name, "w", encoding="utf8") as q:
        q.write("".join(data))
