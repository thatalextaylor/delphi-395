import argparse
import os
import re
from uuid import uuid4

from jinja2 import Environment, PackageLoader
from yaml import load, Loader


def get_config():
    parser = argparse.ArgumentParser(description='Construct Delphi classes from a YAML template.')
    parser.add_argument('source_files', metavar='SOURCE', type=argparse.FileType('r'), nargs='+',
                        help='A YAML template file from which Delphi source will be generated')
    return parser.parse_args()


def split_on_space_underscore_and_upper(name):
    return ((re.sub(r"([A-Z])", r" \1", name)).replace('_', ' ')).split()


def augment_name(target):
    if 'name' in target:
        split_name = split_on_space_underscore_and_upper(target['name'])
        target['name_camelcase'] = split_name[0] + ''.join(x.title() for x in split_name[1:])
        target['name_titlecase'] = ''.join(x.title() for x in split_name)
        target['name_snakecase'] = '_'.join(x.lower() for x in split_name)


def augment_names(data):
    if 'name' in data['type'] and data['type']['name'] is not None:
        augment_name(data['type'])
    if 'requirements' in data['type'] and data['type']['requirements'] is not None:
        for requirement in data['type']['requirements']:
            augment_name(requirement)
    if 'variables' in data['type'] and data['type']['variables'] is not None:
        for variable in data['type']['variables']:
            augment_name(variable)


def augment_uuids(data):
    data['type']['uuid'] = str(uuid4()).upper()


def split_method_header(method):
    match = re.match(r"(function\s+|procedure\s+)(\w+\.)(.*)", method)
    return {
        'definition': match.group(1)+match.group(3),
        'body': method
    }


def augment_methods(data):
    data['type']['methods'] = [split_method_header(method) for method in data['type']['methods']]


def augment_data(data):
    if 'type' in data:
        augment_uuids(data)
        augment_names(data)
        augment_methods(data)


def expand_template(config, template, template_file_name, type_data):
    with open(template_file_name % type_data, 'w') as dest_file:
        dest_file.write(template.render(type_data))


def expand_templates(config, env, source_file):
    data = load(source_file, Loader=Loader)
    augment_data(data)
    for template_file_name in os.listdir('templates'):
        if template_file_name[-4:] == '.pas':
            augment_uuids(data)
            expand_template(config, env.get_template(template_file_name), template_file_name, data['type'])


def main():
    config = get_config()
    env = Environment(lstrip_blocks=True, trim_blocks=True, loader=PackageLoader('delphi-395', 'templates'))
    for source_file in config.source_files:
        expand_templates(config, env, source_file)


if __name__ == "__main__":
    main()
