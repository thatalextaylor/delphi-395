import argparse
import os
import os.path
import re
from uuid import uuid4

from jinja2 import Environment, PackageLoader
from yaml import load, Loader


def get_config():
    parser = argparse.ArgumentParser(description='Construct Delphi classes from a YAML template.')
    parser.add_argument('source_files', metavar='SOURCE', type=argparse.FileType('r'), nargs='+',
                        help='A YAML template file from which Delphi source will be generated')
    parser.add_argument('--null', action='store_true',
                        help='Include a `null` version of the type')
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


def augment_types(data):
    if 'variables' in data['type'] and data['type']['variables'] is not None:
        for variable in data['type']['variables']:
            try:
                variable['contained_generic_type'] = variable['type'][variable['type'].index('<') + 1:variable['type'].rindex('>')]
            except ValueError:
                variable['contained_generic_type'] = None


def augment_uuids(data):
    if 'uuid' not in data['type']:
        data['type']['uuid'] = str(uuid4()).upper()


def create_method_definition(method, class_title):
    first, rest = method.split('\n', 1)
    match = re.match(r"(function\s+|procedure\s+)(.*)", first)
    return {
        'definition': first,
        'body': "{0}T{1}.{2}\n{3}".format(match.group(1), class_title, match.group(2), rest)
    }


def augment_methods(data):
    if 'methods' in data['type'] and data['type']['methods'] is not None:
        data['type']['methods'] = [create_method_definition(method, data['type']['name_titlecase']) for method in data['type']['methods']
                                   if 'name_titlecase' in data['type'] and
                                   data['type']['name_titlecase'] is not None and
                                   'methods' in data['type'] and
                                   data['type']['methods'] is not None]


def augment_data(data):
    if 'type' in data:
        augment_uuids(data)
        augment_names(data)
        augment_types(data)
        augment_methods(data)


def expand_template(config, template, template_file_name, type_data):
    with open(template_file_name % type_data, 'w') as dest_file:
        dest_file.write(template.render(type_data))


def expand_templates(config, env, source_file):
    data = load(source_file, Loader=Loader)
    augment_data(data)
    for template_file_name in os.listdir('templates'):
        if template_file_name[-4:] == '.pas':
            if os.path.exists(template_file_name % data['type']):
                with open(template_file_name % data['type'], 'r') as dst_file:
                    content = dst_file.read()
                    uuid_match = re.search(r"\['\{(\S+)\}'\]", content)
                    if uuid_match:
                        data['type']['uuid'] = uuid_match.group(1)
            augment_uuids(data)
            data['type']['include_null'] = config.null
            expand_template(config, env.get_template(template_file_name), template_file_name, data['type'])
            del data['type']['uuid']


def main():
    config = get_config()
    env = Environment(lstrip_blocks=True, trim_blocks=True, loader=PackageLoader('delphi-395', 'templates'))
    for source_file in config.source_files:
        expand_templates(config, env, source_file)


if __name__ == "__main__":
    main()
