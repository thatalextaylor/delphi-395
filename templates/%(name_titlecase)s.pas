unit {{ name_titlecase }};

{$I sams_5.inc}

interface

{% if uses %}
uses
  DBXJSON,
  {{ uses|join(',\n  ') }};

{% else %}
uses
  DBXJSON;

{% endif %}
type
{% if enumerations %}
  {$SCOPEDENUMS ON}
  {% for enumeration in enumerations %}
  {{ enumeration.name }} = ({{ enumeration['values']|join(', ') }}{% if 'Unknown' not in enumeration['values'] %}, Unknown{% endif %});
  {% endfor %}
  {$SCOPEDENUMS OFF}

{% endif %}
  I{{ name_titlecase }} = interface
  ['{{ "{" + uuid + "}" }}']
  {% for variable in variables %}
    function Get{{ variable.name_titlecase }} : {{ variable.type }};
  {% endfor %}
{% if include_null %}
    function IsNull : Boolean;{% endif %}
  {% if methods %}

  {% for method in methods %}
    {{ method.definition }}
  {% endfor %}
  {% endif %}

  {% for variable in variables %}
    property {{ variable.name_titlecase }}: {{ variable.type }} read Get{{ variable.name_titlecase }};
  {% endfor %}
  end;

  T{{ name_titlecase }} = class(TInterfacedObject, I{{ name_titlecase }})
  private
  {% if requirements %}
  {% for requirement in requirements %}
    F{{ requirement.name_titlecase }}: {{ requirement.type }};
  {% endfor %}

  {% endif %}
  {% for variable in variables %}
    F{{ variable.name_titlecase }}: {{ variable.type }};
  {% endfor %}

    {% if include_null %}class var FNull : I{{ name_titlecase }};
{% endif %}
  public
    constructor Create({% for requirement in requirements if requirement.name and requirement.type %}const A{{ requirement.name_titlecase }} : {{ requirement.type }}{% if not loop.last %}; {% endif %}{% endfor %}); reintroduce; overload;
    constructor Create({% for requirement in requirements if requirement.name and requirement.type %}const A{{ requirement.name_titlecase }} : {{ requirement.type }}{% if not loop.last %}; {% endif %}{% endfor %}{% if requirements and variables %}; {% endif %}{% for variable in variables %}const A{{ variable.name_titlecase }}: {{ variable.type }}{% if not loop.last %}; {% endif %}{% endfor %}); reintroduce; overload;
    {% if include_null %}class constructor CreateClass;
    class function Null : I{{ name_titlecase }};{% endif %}
    class function FromJson(const AJson : String) : I{{ name_titlecase }}; overload;
    class function FromJson(const AJson: TJSONValue) : I{{ name_titlecase }}; overload;
  {% for variable in variables %}
    function Get{{ variable.name_titlecase }} : {{ variable.type }};
  {% endfor %}

    {% if include_null %}function IsNull : Boolean; virtual;
{% endif %}
  {% for variable in variables %}
    procedure Set{{ variable.name_titlecase }}(const A{{ variable.name_titlecase }} : {{ variable.type }});
  {% endfor %}
  {% if methods %}

  {% for method in methods %}
    {{ method.definition }}
  {% endfor %}
  {% endif %}
  end;

implementation

uses
  JsonHelper;

{% if include_null %}type
  TNull{{ name_titlecase }} = class(T{{ name_titlecase }})
  public
    constructor Create();
    function IsNull : Boolean; override;
  end;
{% endif %}
{ T{{ name_titlecase }} }

constructor T{{ name_titlecase }}.Create({% for requirement in requirements if requirement.name and requirement.type %}const A{{ requirement.name_titlecase }} : {{ requirement.type }}{% if not loop.last %}; {% endif %}{% endfor %});
begin
{% if requirements %}
{% for requirement in requirements %}
  F{{ requirement.name_titlecase }} := A{{ requirement.name_titlecase }};
{% endfor %}
{% endif %}
end;

constructor T{{ name_titlecase }}.Create({% for requirement in requirements if requirement.name and requirement.type %}const A{{ requirement.name_titlecase }} : {{ requirement.type }}{% if not loop.last %}; {% endif %}{% endfor %}{% if requirements and variables %}; {% endif %}{% for variable in variables %}const A{{ variable.name_titlecase }}: {{ variable.type }}{% if not loop.last %}; {% endif %}{% endfor %});
begin
{% if requirements %}
{% for requirement in requirements %}
  F{{ requirement.name_titlecase }} := A{{ requirement.name_titlecase }};
{% endfor %}
{% endif %}
{% for variable in variables %}
  F{{ variable.name_titlecase }} := A{{ variable.name_titlecase }};
{% endfor %}
end;

{% if include_null %}class constructor T{{ name_titlecase }}.CreateClass;
begin
  FNull := TNull{{ name_titlecase }}.Create();
end;
{% endif %}
{% if include_null %}class function T{{ name_titlecase }}.Null: I{{ name_titlecase }};
begin
  Result := FNull;
end;
{% endif %}
class function T{{ name_titlecase }}.FromJson(const AJson : String) : I{{ name_titlecase }};
var
  LJobResponse : TJSONValue;
begin
  LJobResponse := nil;
  try
    LJobResponse := TJSONObject(TJSONObject.ParseJSONValue(AJson));
    Result := T{{ name_titlecase }}.FromJson(LJobResponse);
  finally
    LJobResponse.Free;
  end;
end;

class function T{{ name_titlecase }}.FromJson(const AJson: TJSONValue) : I{{ name_titlecase }};
{% set container_namespace = namespace(needs_container=false) %}{% for variable in variables %}
  {% if variable.type|lower in enumerations|map(attribute='name')|map('lower') %}{% set container_namespace.needs_container = true %}
  {% elif variable.type.lower().startswith('tlist<') %}{% set container_namespace.needs_container = true %}
  {% endif %}
{% endfor %}
{% if container_namespace.needs_container %}
var
  LContainer : TJsonValue;
{% set container_namespace = namespace(needs_container=false) %}{% for variable in variables %}
  {% if variable.type|lower in enumerations|map(attribute='name')|map('lower') %}{% set container_namespace.needs_container = true %}
  L{{ variable.name_titlecase }} : {{ variable.type }};
  {% elif variable.type.lower().startswith('tlist<') %}{% set container_namespace.needs_container = true %}
  L{{ variable.name_titlecase }} : {{ variable.type }};
  {% endif %}
{% endfor %}
{% endif %}
begin
{% if container_namespace.needs_container %}
{% for variable in variables %}
  {% if variable.type|lower in enumerations|map(attribute='name')|map('lower') %}
  if AJson.TryGetValue<TJSONValue>('{{variable.name_camelcase}}', {out}LContainer) and not LContainer.Null then
    L{{variable.name_titlecase}} := LContainer.AsEnum<{{variable.type}}>()
  else
    L{{variable.name_titlecase}} := {{variable.type}}.Unknown;
  {% elif variable.type.lower().startswith('tlist<') %}
  if AJson.TryGetValue<TJSONValue>('{{variable.name_camelcase}}', {out}LContainer) and not LContainer.Null then
    L{{ variable.name_titlecase }} := {{ variable.contained_generic_type }}.FromJsonList(LContainer as TJSONArray)
  else
    L{{ variable.name_titlecase }} := nil;
  {% endif %}
{% endfor %}

{% endif %}
  Result := T{{ name_titlecase }}.Create(
{% for variable in variables %}
  {% if variable.type|lower in ('string', 'integer', 'tsamsfloat') %}
    AJson.GetValue<{{ variable.type }}>('{{variable.name_camelcase}}'){% if not loop.last %},{% endif %}

  {% elif variable.type|lower in enumerations|map(attribute='name')|map('lower') %}
    L{{ variable.name_titlecase }}{% if not loop.last %},{% endif %}
    
  {% elif variable.type.lower().startswith('tlist<') %}
    L{{ variable.name_titlecase }}{% if not loop.last %},{% endif %}
    
  {% else %}
    {{ variable.type }}.FromJson(AJson.Get('{{variable.name_camelcase}}')){% if not loop.last %},{% endif %}
    
  {% endif %}
{% endfor %}
  );
end;

{% for variable in variables %}
function T{{ name_titlecase }}.Get{{ variable.name_titlecase }}: {{ variable.type }};
begin
  Result := F{{ variable.name_titlecase }};
end;

{% endfor %}
{% if include_null %}function T{{ name_titlecase }}.IsNull: Boolean;
begin
  Result := False;
end;
{% endif %}
{% for variable in variables %}
procedure T{{ name_titlecase }}.Set{{ variable.name_titlecase }}(const A{{ variable.name_titlecase }} : {{ variable.type }});
begin
  F{{ variable.name_titlecase }} := A{{ variable.name_titlecase }};
end;

{% endfor %}
{% for method in methods %}
{{ method.body }}
{% endfor %}
{% if include_null %}{ TNull{{ name_titlecase }} }

constructor TNull{{ name_titlecase }}.Create;
begin
  //Should set everything to a 'safe' default
end;

function TNull{{ name_titlecase }}.IsNull: Boolean;
begin
  Result := True;
end;
{% endif %}
end.

