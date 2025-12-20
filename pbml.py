import re
import os
import sys
import json
import shutil
import subprocess
from urllib.request import urlopen
from typing import List, Dict, Any

VERSION = 0.4

CORONA_ARCHIVER_URL = 'https://raw.githubusercontent.com/0BuRner/corona-archiver/refs/heads/master/corona-archiver.py'
CORONA_ARCHIVER_FILE_NAME = 'corona-archiver.py'

UNLUAC_URL = 'https://deac-fra.dl.sourceforge.net/project/unluac/Unstable/unluac_2025_10_19.jar'
UNLUAC_FILE_NAME = 'unluac.jar'

def run_cmd(*args):
    subprocess.Popen(args).wait()


def parse_line(line: str, stack_size: int, last_const: int, variables: Dict[str, str]) -> str:
    line = re.sub(r'\$r(\d+)', lambda m: 'r' + str(stack_size + int(m.group(1))), line)
    line = re.sub(r'\$k(\d+)', lambda m: 'k' + str(last_const + int(m.group(1))), line)
    line = re.sub(r'\$\{(\w+)\}', lambda m: variables[m.group(1)] if m.group(1) in variables else 'None', line)
    return line


# apply patch to file
def apply_patch(lines: List[str], patch: Dict[str, Any]) -> None:
    actions = patch['actions']
    function_name = patch['functionName'] if 'functionName' in patch else None
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
    function_mode = True

    if function_name is None:
        state = 1
        function_end = len(lines) - 1
        function_mode = False

    if 'set' in patch:
        for i in patch['set']:
            variables[i] = parse_line(patch['set'][i], stack_size, last_const, variables)

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
        elif state == 3 and function_mode and re.match('^return', line):
            function_end = i
            break

        prev_line = line

    for i in range(function_start, function_end):
        line = lines[i]

        if function_mode and re.match('^return.*$', line): break

        for j in range(len(actions)):
            if j in ignore_actions: continue
            action = actions[j]

            if ('ifDefined' not in action or len(list(filter(lambda v: v not in variables, action['ifDefined']))) == 0) and \
            (matches := re.match(parse_line(action['match'], stack_size, last_const, variables), line)):
                if 'if' in action:
                    parsed = parse_line(action['if'], stack_size, last_const, variables)

                    if not re.match(r'^(".+"|\'.+\'|and|or|xor|not|[\d\s+\-*/><=()]+)+$', parsed):
                        raise ValueError('Invalid expression')
                    
                    if not eval(parsed): continue

                if not ('processAll' in action and action['processAll']): ignore_actions.append(j)
                start_index = i if 'insertBefore' in action and action['insertBefore'] else i + 1

                if 'replace' in action:
                    lines[i] = parse_line(re.sub(r'\$g(\d+)', lambda m: matches.group(int(m.group(1))), action['replace']), stack_size, last_const, variables)

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

                if 'remove' in action:
                    del lines[i]


logs = []

def main():
    # parse command line arguments
    no_logo: bool = False
    silent: bool = False
    force: bool = False
    debug: bool = False
    patch: str | None = None
    game_dir: str | None = None
    resources_dir: str = 'Resources'
    data_dir: str = 'Resources'

    args = sys.argv[1:]
    for i in range(len(args)):
        arg = args[i]
        next_arg = args[i + 1] if i < len(args) - 1 else None

        match arg:
            case '--help' | '-h' | '-?' | '/?':
                print(f'usage: {sys.argv[0]} [--no-logo|-N] [--silent|-s] [--debug|-D] [--android|-a] [--force|-f] [--patch|-p <patch file 1>,<patch file 2>,...]] [--game-dir|-d <game dir>] [--resources-dir|-R <resources dir name>]')
                sys.exit()
            case '--no-logo' | '-N':
                no_logo = True
            case '--silent' | '-s':
                silent = True
            case '--debug' | '-D':
                debug = True
            case '--android' | '-a':
                resources_dir = 'assets'
                data_dir = '/storage/emulated/0/pbml'
            case '--force' | '-f':
                force = True
            case '--patch' | '-p':
                patch = next_arg
            case '--game-dir' | '-d':
                game_dir = next_arg
            case '--resources-dir' | '-R':
                resources_dir = next_arg


    script_dir = os.path.dirname(os.path.abspath(__file__))

    if game_dir is None:
        game_dir = input('Path to game root directory (where Progressbar95.exe is located): ')

    # pbml patches
    pbml_patches = [
        {
            'functionName': 'main/f0',
            'addRegisters': 2,
            'addConstants': ['"Game"', '"dofile"', f'"{game_dir.replace("\\", "/")}/{resources_dir}/pbml/init.lua"', f'"{game_dir.replace("\\", "/")}/{resources_dir}/pbml/main.lua"'],
            'actions': [
                {
                    'match': r'\.constant\s+(k\d+)\s+"BeginMenu"',
                    'set': {
                        'constNumber': '$g1'
                    }
                },
                {
                    'match': r'getglobal\s+r0\s+k0',
                    'code': [
                        'getglobal $r0 $k1',
                        'loadk $r1 $k2',
                        'call $r0 2 1'
                    ],
                    'insertBefore': True
                },
                {
                    'ifDefined': ['constNumber'],
                    'match': r'loadk\s+r\d+\s+${constNumber}',
                    'code': [
                        'setglobal r1 $k0',
                        'getglobal $r0 $k1',
                        'loadk $r1 $k3',
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
                        'getglobal $r0 $k0',
                        'move $r1 r1',
                        'call $r0 2 1'
                    ]
                }
            ]
        }
    ]

    def write(text: str):
        logs.append(text + '\n')
        if not silent: print(text)


    if not no_logo: write(f'PBML v{VERSION}')

    # check requirements
    if shutil.which('java') is None:
        raise Exception('Java not found')

    if not os.path.isfile(os.path.join(script_dir, CORONA_ARCHIVER_FILE_NAME)):
        write('Downloading corona-archiver...')
        with open(os.path.join(script_dir, CORONA_ARCHIVER_FILE_NAME), 'wb') as file:
            file.write(urlopen(CORONA_ARCHIVER_URL).read())

    if not os.path.isfile(os.path.join(script_dir, UNLUAC_FILE_NAME)):
        write('Downloading unluac...')
        with open(os.path.join(script_dir, UNLUAC_FILE_NAME), 'wb') as file:
            file.write(urlopen(UNLUAC_URL).read())

    resource_car_path = os.path.join(game_dir, resources_dir, 'resource.car')

    if not os.path.isfile(resource_car_path):
        raise Exception(f'File "{resource_car_path}" not found, make sure you\'ve entered correct path')

    if not os.path.isdir(os.path.join(script_dir, 'res')): os.mkdir(os.path.join(script_dir, 'res'))

    write('Extracting resource.car...')
    run_cmd(sys.executable, os.path.join(script_dir, CORONA_ARCHIVER_FILE_NAME), '-u', resource_car_path, os.path.join(script_dir, 'res'))

    write('Disassembling main.lu...')
    run_cmd('java', '-jar', os.path.join(script_dir, UNLUAC_FILE_NAME), '--disassemble', os.path.join(script_dir, 'res', 'main.lu'), '--output', os.path.join(script_dir, 'main_src.txt'))

    write('Patching main.lu...')
    main_src = open(os.path.join(script_dir, 'main_src.txt'), 'r')
    main_lines = main_src.read().split('\n')
    main_src.close()

    patches = []
    if patch is None:
        patches = pbml_patches
    else:
        for file_path in patch.split(','):
            with open(file_path, 'r') as json_file:
                json_data = json.load(json_file)

                for p in json_data['patches']:
                    patches.append(p)

    for ptch in patches:
        apply_patch(main_lines, ptch)

    main_dst = open(os.path.join(script_dir, 'main_dst.txt'), 'w')
    main_dst.write('\n'.join(main_lines))
    main_dst.close()

    write('Assembling main.lu...')
    run_cmd('java', '-jar', os.path.join(script_dir, UNLUAC_FILE_NAME), '--assemble', os.path.join(script_dir, 'main_dst.txt'), '--output', os.path.join(script_dir, 'res', 'main.lu'))

    write('Packing resource.car...')
    shutil.copyfile(resource_car_path, os.path.join(game_dir, resources_dir, 'resource.car.bak'))
    run_cmd(sys.executable, os.path.join(script_dir, CORONA_ARCHIVER_FILE_NAME), '-p', 'res', resource_car_path)

    if not patch:
        write('Creating PBML files...')

        if not os.path.isdir(os.path.join(game_dir, resources_dir, 'pbml')):
            os.mkdir(os.path.join(game_dir, resources_dir, 'pbml'))

        if not os.path.isdir(os.path.join(game_dir, resources_dir, 'mods')):
            os.mkdir(os.path.join(game_dir, resources_dir, 'mods'))

        if not os.path.isdir(os.path.join(game_dir, 'pbml')):
            os.mkdir(os.path.join(game_dir, 'pbml'))

        shutil.copyfile(os.path.abspath(__file__), os.path.join(game_dir, 'pbml', 'pbml.py'))
        shutil.copyfile(os.path.join(script_dir, CORONA_ARCHIVER_FILE_NAME), os.path.join(game_dir, 'pbml', CORONA_ARCHIVER_FILE_NAME))
        shutil.copyfile(os.path.join(script_dir, UNLUAC_FILE_NAME), os.path.join(game_dir, 'pbml', UNLUAC_FILE_NAME))

        for script in os.listdir(os.path.join(script_dir, 'scripts')):
            if script == '.' or script == '..': continue

            with open(os.path.join(script_dir, 'scripts', script), 'r') as script_data:
                with open(os.path.join(game_dir, resources_dir, 'pbml', script), 'w') as script_wrt:
                    code = script_data.read()
                    code = code.replace('__PBML_GAME_DIRECTORY__', game_dir.replace('\\', '/'))
                    code = code.replace('__PBML_RESOURCES_DIRECTORY__', os.path.join(game_dir, resources_dir).replace('\\', '/'))
                    code = code.replace('__PBML_DATA_DIRECTORY__', os.path.join(game_dir, data_dir).replace('\\', '/'))
                    code = code.replace('__PBML_PYTHON_PATH__', sys.executable.replace('\\', '/'))
                    code = code.replace('__PBML_PATCHER_PATH__', os.path.abspath(__file__).replace('\\', '/'))
                    script_wrt.write(code)

    write('Cleaning up...')
    os.remove(os.path.join(script_dir, 'main_src.txt'))
    if not debug: os.remove(os.path.join(script_dir, 'main_dst.txt'))
    shutil.rmtree(os.path.join(script_dir, 'res'))

    write('')
    write('Completed')


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