import re
import os
import sys
import json
import shutil
import subprocess
from urllib.request import urlopen
from typing import List, Dict, Any

VERSION = 0.3

CORONA_ARCHIVER_URL = 'https://raw.githubusercontent.com/0BuRner/corona-archiver/refs/heads/master/corona-archiver.py'
CORONA_ARCHIVER_FILE_NAME = 'corona-archiver.py'

UNLUAC_URL = 'https://deac-fra.dl.sourceforge.net/project/unluac/Unstable/unluac_2025_10_19.jar'
UNLUAC_FILE_NAME = 'unluac.jar'

def run_cmd(*args):
    subprocess.Popen(args).wait()


def parse_line(line: str, stack_size: int, last_const: int, variables: Dict[str, str]) -> str:
    line = re.sub(r'\$r(\d+)', lambda m: 'r' + str(stack_size + int(m.group(1))), line)
    line = re.sub(r'\$k(\d+)', lambda m: 'k' + str(last_const + int(m.group(1))), line)
    line = re.sub(r'\$\{(\w+)\}', lambda m: variables[m.group(1)], line)
    return line


# apply patch to file
def apply_patch(lines: List[str], patch: Dict[str, Any]) -> None:
    actions = patch['actions']
    function_name = patch['functionName']
    add_registers = patch['addRegisters'] if 'addRegisters' in patch else 0
    add_constants = patch['addConstants'] if 'addConstants' in patch else []

    state = 0
    prev_line = ''
    stack_size = 0
    last_const = 0
    variables = {}
    ignore_actions = []
    function_start = 0
    function_end = 0

    for i in range(len(lines)):
        line = lines[i].strip()

        if state == 0 and re.match(rf'^\.function\s+{function_name}$', line):
            state = 1
            function_start = i
        elif state == 1 and (matches := re.match(r'^\.maxstacksize\s+(\d+)$', line)):
            state = 2
            stack_size = int(matches.group(1))
            lines[i] = '.maxstacksize ' + str(stack_size + add_registers)
        elif state == 2 and len(line) == 0 and (matches := re.match(r'^\.constant\s+k(\d+)\s+.*$', prev_line)):
            state = 3
            last_const = int(matches.group(1)) + 1

            for j in range(len(add_constants)):
                lines.insert(i + j, f'.constant k{last_const + j} {add_constants[j]}')
        elif state == 3 and re.match('^return', line):
            function_end = i
            break

        prev_line = line

    for i in range(function_start, function_end):
        line = lines[i]

        if re.match('^return.*$', line): break

        for j in range(len(actions)):
            if j in ignore_actions: continue
            action = actions[j]

            if ('ifDefined' not in action or len(list(filter(lambda v: v not in variables, action['ifDefined']))) == 0) and \
            (matches := re.match(parse_line(action['match'], stack_size, last_const, variables), line)):
                if not ('processAll' in action and action['processAll']): ignore_actions.append(j)
                start_index = i if 'insertBefore' in action and action['insertBefore'] else i + 1

                if 'code' in action:
                    for k in range(len(action['code'])):
                        code_line = re.sub(r'\$g(\d+)', lambda m: matches.group(int(m.group(1))), action['code'][k]) # pyright: ignore[reportOptionalMemberAccess]
                        code_line = parse_line(code_line, stack_size, last_const, variables)
                        lines.insert(start_index + k, code_line)
                
                if 'set' in action:
                    for k in action['set']:
                        data = re.sub(r'\$g(\d+)', lambda m: matches.group(int(m.group(1))), action['set'][k]) # type: ignore
                        data = parse_line(data, stack_size, last_const, variables)
                        variables[k] = data


# pbml patches
pbml_patches = [
        {
        'functionName': 'main/f0',
        'addRegisters': 2,
        'addConstants': ['"Game"', '"dofile"', '"Resources/pbml/pbml.lua"'],
        'actions': [
            {
                'match': r'\.constant\s+(k\d+)\s+"BeginMenu"',
                'set': {
                    'constNumber': '$g1'
                }
            },
            {
                'ifDefined': ['constNumber'],
                'match': r'loadk\s+r\d+\s+${constNumber}',
                'code': [
                    'setglobal r1 $k0',
                    'getglobal $r0 $k1',
                    'loadk $r1 $k2',
                    'call $r0 2 1'
                ]
            }
        ]
    },
    {
        'functionName': 'main/f0/f214/f1/f1/f3',
        'addRegisters': 2,
        'addConstants': ['"_w_pbml_ProcessPBOSList"'],
        'actions': [
            {
                'match': r'\.constant\s+(k\d+)\s+"P13"',
                'set': {
                    'constNumber': '$g1'
                }
            },
            {
                'ifDefined': ['constNumber'],
                'match': r'loadk\s+r\d+\s+${constNumber}',
                'set': {
                    'foundPbOSList': '1'
                }
            },
            {
                'ifDefined': ['foundPbOSList'],
                'match': r'setlist',
                'code': [
                    'getglobal $r0 $k0 ; wuwa here!',
                    'move $r1 r1',
                    'call $r0 2 1'
                ]
            }
        ]
    }
]

logs = []

def main():
    # parse command line arguments
    no_logo: bool = False
    silent: bool = False
    debug: bool = False
    patch: str | None = None
    game_dir: str | None = None

    args = sys.argv[1:]
    for i in range(len(args)):
        arg = args[i]
        next_arg = args[i + 1] if i < len(args) - 1 else None

        match arg:
            case '--help' | '-h' | '-?' | '/?':
                print(f'usage: {sys.argv[0]} [--no-logo|-N] [--silent|-s] [--debug|-D] [--patch|-p <patch file 1>,<patch file 2>,...]] [--game-dir|-d <game dir>]')
                sys.exit()
            case '--no-logo' | '-N':
                no_logo = True
            case '--silent' | '-s':
                silent = True
            case '--debug' | '-D':
                debug = True
            case '--patch' | '-p':
                patch = next_arg
            case '--game-dir' | '-d':
                game_dir = next_arg

    def write(text: str):
        logs.append(text + '\n')
        if not silent: print(text)


    if not no_logo: write(f'PBML v{VERSION}')

    # check requirements
    if shutil.which('java') is None:
        raise Exception('Java not found')

    if not os.path.isfile(CORONA_ARCHIVER_FILE_NAME):
        write('Downloading corona-archiver...')
        with open(CORONA_ARCHIVER_FILE_NAME, 'wb') as file:
            file.write(urlopen(CORONA_ARCHIVER_URL).read())

    if not os.path.isfile(UNLUAC_FILE_NAME):
        write('Downloading unluac...')
        with open(UNLUAC_FILE_NAME, 'wb') as file:
            file.write(urlopen(UNLUAC_URL).read())
    
    if game_dir is None:
        game_dir = input('Path to game root directory (where Progressbar95.exe is located): ')

    resource_car_path = os.path.join(game_dir, 'Resources', 'resource.car')

    if not os.path.isfile(resource_car_path):
        raise Exception(f'File "{resource_car_path}" not found, make sure you\'ve entered correct path')
    
    if not os.path.isdir('res'): os.mkdir('res')

    write('Extracting resource.car...')
    run_cmd(sys.executable, 'corona-archiver.py', '-u', resource_car_path, 'res')

    write('Disassembling main.lu...')
    run_cmd('java', '-jar', 'unluac.jar', '--disassemble', os.path.join('res', 'main.lu'), '--output', 'main_src.txt')

    write('Patching main.lu...')
    main_src = open('main_src.txt', 'r')
    main_lines = main_src.read().split('\n')
    main_src.close()

    patches = []
    if patch is None:
        patches = pbml_patches
    else:
        for file_path in patch.split(','):
            with open(file_path, 'r') as json_file:
                patches.append(json.load(json_file))

    for ptch in patches:
        apply_patch(main_lines, ptch)
    
    main_dst = open('main_dst.txt', 'w')
    main_dst.write('\n'.join(main_lines))
    main_dst.close()

    write('Assembling main.lu...')
    run_cmd('java', '-jar', 'unluac.jar', '--assemble', 'main_dst.txt', '--output', os.path.join('res', 'main.lu'))

    write('Packing resource.car...')
    shutil.copyfile(resource_car_path, os.path.join(game_dir, 'Resources', 'resource.car.bak'))
    run_cmd(sys.executable, 'corona-archiver.py', '-p', 'res', resource_car_path)

    write('Creating PBML files...')

    if not os.path.isdir(os.path.join(game_dir, 'Resources', 'pbml')):
        os.mkdir(os.path.join(game_dir, 'Resources', 'pbml'))

    if not os.path.isdir(os.path.join(game_dir, 'Resources', 'mods')):
        os.mkdir(os.path.join(game_dir, 'Resources', 'mods'))

    for script in os.listdir('scripts'):
        if script == '.' or script == '..': continue
        shutil.copyfile(os.path.join('scripts', script), os.path.join(game_dir, 'Resources', 'pbml', script))

    write('Cleaning up...')
    os.remove('main_src.txt')
    os.remove('main_dst.txt')
    shutil.rmtree('res')

    write('')
    write('PBML installed!')


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('Interrupted by user')
    except Exception as e:
        logs.append(str(e))
        with open('crashlog.txt', 'w') as log: log.writelines(logs)
        print(f'Fatal error: {e}')
    finally:
        if len(sys.argv) == 1: input()