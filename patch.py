import re

reader = open('main_src.txt', 'r', encoding='utf-8')
writer = open('main_dst.txt', 'w', encoding='utf-8')

state = 0
prev_line = ''
stack_size = 0
last_const = 0
begin_menu_const = 0

for line in reader:
    add_line = True
    line = line.strip()

    if state == 0 and (matches := re.match(r'^\.function\s+main/f0$', line)):
        state = 1
    elif state == 1 and (matches := re.match(r'^\.maxstacksize\s+(\d+)$', line)):
        state = 2
        stack_size = int(matches.group(1))
        line = '.maxstacksize ' + str(stack_size + 2)
    elif state == 2 and (matches := re.match(r'^\.constant\s+k(\d+)\s+"BeginMenu"$', line)):
        state = 3
        begin_menu_const = matches.group(1)
    elif state == 3 and len(line.strip()) == 0 and (matches := re.match(r'^\.constant\s+k(\d+)\s+.*$', prev_line)):
        state = 4
        last_const = int(matches.group(1))

        add_line = False
        writer.write(f'.constant k{last_const+1} "dofile"\n')
        writer.write(f'.constant k{last_const+2} "Resources/pbml/pbml.lua"\n')
        writer.write(f'.constant k{last_const+3} "Game"\n\n')
    elif state == 4 and (matches := re.match(fr'^loadk\s+r\d+\s+k{begin_menu_const}', line)):
        state = 5

        add_line = False
        writer.write(line + '\n')
        writer.write(f'setglobal r1 k{last_const+3}\n')
        writer.write(f'getglobal r{stack_size} k{last_const+1}\n')
        writer.write(f'loadk r{stack_size+1} k{last_const+2}\n')
        writer.write(f'call r{stack_size} 2 1\n')
    
    prev_line = line
    if add_line: writer.write(line + '\n')

reader.close()
writer.flush()
writer.close()