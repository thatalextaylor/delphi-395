unit {{ name_titlecase }}Builder;

{$I sams_5.inc}

interface

uses
{% if requirements %}
  {{ requirements|join(',\n  ', attribute='unit') }},
{% endif %}
  {{ name_titlecase }};

type
  I{{ name_titlecase }}Builder = interface
  ['{{ "{" + uuid + "}" }}']
  {% for variable in variables %}
    function With{{ variable.name_titlecase }}(const A{{ variable.name_titlecase }} : {{ variable.type }}) : I{{ name_titlecase }}Builder;
  {% endfor %}

    function Build() : I{{ name_titlecase }};
  end;

  T{{ name_titlecase }}Builder = class(TInterfacedObject, I{{ name_titlecase }}Builder)
  private
  {% if requirements %}
  {% for requirement in requirements %}
    F{{ requirement.name_titlecase }}: {{ requirement.type }};
  {% endfor %}
  {% endif %}

  {% for variable in variables %}
    F{{ variable.name_titlecase }}: {{ variable.type }};
  {% endfor %}
  public
    constructor Create({% if requirements %}{% for requirement in requirements[:-1] %}const A{{ requirement.name_titlecase }} : {{ requirement.type }}; {% endfor %}const A{{ requirements[-1].name_titlecase }} : {{ requirements[-1].type }}{% endif %});

    class function New({% if requirements %}{% for requirement in requirements[:-1] %}const A{{ requirement.name_titlecase }} : {{ requirement.type }}; {% endfor %}const A{{ requirements[-1].name_titlecase }} : {{ requirements[-1].type }}{% endif %}) : I{{ name_titlecase }}Builder;

  {% for variable in variables %}
    function With{{ variable.name_titlecase }}(const A{{ variable.name_titlecase }} : {{ variable.type }}) : I{{ name_titlecase }}Builder;
  {% endfor %}

    function Build() : I{{ name_titlecase }};
  end;

implementation

{ T{{ name_titlecase }}Builder }

//----------------------------------------------------------------------------------------------------------------------
constructor T{{ name_titlecase }}Builder.Create({% if requirements %}{% for requirement in requirements[:-1] %}const A{{ requirement.name_titlecase }} : {{ requirement.type }}; {% endfor %}const A{{ requirements[-1].name_titlecase }} : {{ requirements[-1].type }}{% endif %});
begin
{% if requirements %}
{% for requirement in requirements %}
  F{{ requirement.name_titlecase }} := A{{ requirement.name_titlecase }};
{% endfor %}
{% endif %}
end;

//----------------------------------------------------------------------------------------------------------------------
class function T{{ name_titlecase }}Builder.New({% if requirements %}{% for requirement in requirements[:-1] %}const A{{ requirement.name_titlecase }} : {{ requirement.type }}; {% endfor %}const A{{ requirements[-1].name_titlecase }} : {{ requirements[-1].type }}{% endif %}): I{{ name_titlecase }}Builder;
begin
  Result := T{{ name_titlecase }}Builder.Create({% if requirements %}{% for requirement in requirements[:-1] %}A{{ requirement.name_titlecase }}, {% endfor %}A{{ requirements[-1].name_titlecase }}{% endif %});
end;

{% for variable in variables %}
//----------------------------------------------------------------------------------------------------------------------
function T{{ name_titlecase }}.With{{ variable.name_titlecase }}(const A{{ variable.name_titlecase }} : {{ variable.type }}): I{{ name_titlecase }}Builder;
begin
  F{{ variable.name_titlecase }} := A{{ variable.name_titlecase }};
  Result := Self;
end;

{% endfor %}
//----------------------------------------------------------------------------------------------------------------------
function T{{ name_titlecase }}Builder.Build: I{{ name_titlecase }};
var
  L{{ name_titlecase }} : T{{ name_titlecase }};
begin
  L{{ name_titlecase }} := T{{ name_titlecase }}.Create({% if requirements %}{% for requirement in requirements[:-1] %}F{{ requirement.name_titlecase }}, {% endfor %}F{{ requirements[-1].name_titlecase }}{% endif %});
  {% for variable in variables %}
  L{{ name_titlecase }}.Set{{ variable.name_titlecase }}(F{{ variable.name_titlecase }});
  {% endfor %}
  Result := L{{ name_titlecase }};
end;

//----------------------------------------------------------------------------------------------------------------------
end.
//----------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------
