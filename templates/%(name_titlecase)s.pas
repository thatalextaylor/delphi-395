unit {{ name_titlecase }};

{$I sams_5.inc}

interface

{% if requirements %}
uses
  {{ requirements|join(',\n  ', attribute='unit') }};

{% endif %}
type
{% if enumerations %}
  {$SCOPEDENUMS ON}
  {% for enumeration in enumerations %}
  {{ enumeration.name }} = ({{ enumeration['values']|join(', ') }});
  {% endfor %}
  {$SCOPEDENUMS OFF}

{% endif %}
  I{{ name_titlecase }} = interface
  ['{{ "{" + uuid + "}" }}']
  {% for variable in variables %}
    function Get{{ variable.name_titlecase }} : {{ variable.type }};
  {% endfor %}

    function IsNull : Boolean;

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

    class var FNull : I{{ name_titlecase }};

  public
    constructor Create({% for requirement in requirements if requirement.name and requirement.type %}const A{{ requirement.name_titlecase }} : {{ requirement.type }}{% if not loop.last %}; {% endif %}{% endfor %}); reintroduce;
    class constructor CreateClass;
    class function Null : I{{ name_titlecase }};

  {% for variable in variables %}
    function Get{{ variable.name_titlecase }} : {{ variable.type }};
  {% endfor %}

    function IsNull : Boolean; virtual;

  {% for variable in variables %}
    procedure Set{{ variable.name_titlecase }}(const A{{ variable.name_titlecase }} : {{ variable.type }});
  {% endfor %}
  end;

implementation

type
  TNull{{ name_titlecase }} = class(T{{ name_titlecase }})
  public
    constructor Create();
    function IsNull : Boolean; override;
  end;

{ T{{ name_titlecase }} }

//----------------------------------------------------------------------------------------------------------------------
constructor T{{ name_titlecase }}.Create({% for requirement in requirements if requirement.name and requirement.type %}const A{{ requirement.name_titlecase }} : {{ requirement.type }}{% if not loop.last %}; {% endif %}{% endfor %});
begin
{% if requirements %}
{% for requirement in requirements %}
  F{{ requirement.name_titlecase }} := A{{ requirement.name_titlecase }};
{% endfor %}
{% endif %}
end;

//----------------------------------------------------------------------------------------------------------------------
class constructor T{{ name_titlecase }}.CreateClass;
begin
  FNull := TNull{{ name_titlecase }}.Create();
end;

//----------------------------------------------------------------------------------------------------------------------
class function T{{ name_titlecase }}.Null: I{{ name_titlecase }};
begin
  Result := FNull;
end;

{% for variable in variables %}
//----------------------------------------------------------------------------------------------------------------------
function T{{ name_titlecase }}.Get{{ variable.name_titlecase }}: {{ variable.type }};
begin
  Result := F{{ variable.name_titlecase }};
end;

{% endfor %}
//----------------------------------------------------------------------------------------------------------------------
function T{{ name_titlecase }}.IsNull: Boolean;
begin
  Result := False;
end;

{% for variable in variables %}
//----------------------------------------------------------------------------------------------------------------------
procedure T{{ name_titlecase }}.Set{{ variable.name_titlecase }}(const A{{ variable.name_titlecase }} : {{ variable.type }});
begin
  F{{ variable.name_titlecase }} := A{{ variable.name_titlecase }};
end;

{% endfor %}
//----------------------------------------------------------------------------------------------------------------------
{ TNull{{ name_titlecase }} }

//----------------------------------------------------------------------------------------------------------------------
constructor TNull{{ name_titlecase }}.Create;
begin
  //Should set everything to a 'safe' default
end;

//----------------------------------------------------------------------------------------------------------------------
function TNull{{ name_titlecase }}.IsNull: Boolean;
begin
  Result := True;
end;

//----------------------------------------------------------------------------------------------------------------------
end.
//----------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------

