const source = ``;

const lines = source.split('\n');

const table = {};
for (let sourceTableIndex = 0; sourceTableIndex < 3; sourceTableIndex++) {
  const firstValueIndex = lines.length > 200
    ? sourceTableIndex * 201 + 1
    : 0;

  for (let i = firstValueIndex; i < firstValueIndex + 200; i += 2) {
    const value = lines[i].replace(':', '');
    table[value] = lines[i + 1];
  }

  const jsonTable = JSON.stringify(table);

  if (firstValueIndex > 0) {
    console.log(lines[firstValueIndex - 1]);
  }
  console.log(jsonTable.substring(1, jsonTable.length - 1));
}
