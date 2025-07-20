---
Date:
  - {% if dateAdded %}{{dateAdded | format("YYYY-MM-DD")}}{% endif %}
date published: {{date | format("YYYY") | int}}
aliases:
  - {{ title }}
author:
{% for creator in creators -%}
  - {{ creator.firstName }} {{ creator.lastName }}
{% endfor %}tags: 
  - citation
  - {{itemType}}
{%- for tag in tags %}
  - {{ tag.tag }}
{% endfor %}
cssclasses:
  - daily
cover: {%- set grayItems = [] -%}
{%- for a in annotations -%}
  {%- if a.type == "image" and a.color == "#aaaaaa" -%}
    {%- set _ = grayItems.push(a) -%}
  {%- endif -%}
{%- endfor -%}

{%- for i in grayItems -%}
  {# First remove the folder "base_name/", then remove "output_path-" #}
  {%- set partial = i.imageRelativePath | replace("03 - Assets/Images/", "") -%}
  {%- set final = partial | replace("output_path-", "") %} ![[{{ final }}]]
{% endfor %}
---
# [[{{title}}]]
## By: {% for creator in creators %}[[{{ creator.firstName }} {{ creator.lastName }}]]{% if not loop.last %}, {% endif %}{% endfor %}

[Zotero Link]({{select}})
>[!quote]- Abstract
>{{abstractNote}}

{%-
    set zoteroColors = {
        "#000000": "black",
        "#404040": "greyblack",
        "#808080": "darkgrey",
        "#aaaaaa": "grey",
        "#5fb236": "green",
        "#ff6666": "red",
        "#ffd400": "yellow",
        "#f19837": "orange",
        "#a28ae5": "purple",
        "#e56eee": "magenta",
        "#2ea8e5": "blue",
        "#3f51b5": "indigo"
    }
-%}

{%-  
set colorHeading = {
  "grey": "> [!grey]- Chapters",
  "yellow": ">[!yellow]- Key Definitions & Concepts",  
  "green": "> [!green]- Agreements",  
  "red": "> [!red]- Disagreements",  
  "blue": "> [!blue]- Citations",  
  "purple": "> [!purple]- Points to Revisit",  
  "orange": "> [!orange]- Definitions",  
  "magenta": "> [!pink]- Confusion"
}
-%}

{%- set newAnnotations = [] -%}
{%- set annotations = annotations | filterby("date", "dateafter", lastImportDate) %}

{# Convert color hex to label (#aaaaaa => "grey", etc.) #}
{%- for annot in annotations -%}
  {%- if annot.color in zoteroColors -%}
    {%- set customColor = zoteroColors[annot.color] -%}
  {%- elif annot.colorCategory|lower in colorHeading -%}
    {%- set customColor = annot.colorCategory|lower -%}
  {%- else -%}
    {%- set customColor = "other" -%}
  {%- endif -%}
  {%- set newAnnotations = (newAnnotations.push({"annotation": annot, "customColor": customColor}), newAnnotations) -%}
{%- endfor -%}

### Notes
---
{% persist "notes" %}
{%- set greyItems = newAnnotations | filterby("customColor", "startswith", "grey") -%}

{%- if greyItems.length > 0 %}
> [!grey]- Index{% endif %}
{%- for entry in greyItems -%}
  {%- set annot = entry.annotation -%}
  {% if annot.type == "highlight" and annot.source == "zotero" %}
> ### {{ annot.annotatedText }}
[Page {{ annot.pageLabel }}]({{ annot.desktopURI }}){% elif annot.type == "underline" and annot.source == "zotero" %}
>1. ~
><span style="display: inline-block; width: 100%; text-align: right;">[{{ annot.pageLabel }}]({{ annot.desktopURI }})</span>



  {%- endif -%}

{%- endfor %}

### Citations
---
{# --------------------------------------------- #}
{# 1) LOOP #1: All Colors EXCEPT Grey            #}
{# --------------------------------------------- #}
{%- for color, heading in colorHeading -%}
{%- if color != "grey" -%}
{%- set items = newAnnotations | filterby("customColor", "startswith", color) %}

{%- if items.length > 0 %}
{{ heading }}
{%- endif -%}

{%- for entry in items -%}
{%- set annot = entry.annotation -%}

{%- if annot.annotatedText %}
>---
> "{{annot.annotatedText}}{% if annot.hashTags %}{{annot.hashTags}}{% endif %}"
{%- endif %}

{%- if annot.imageRelativePath %}
> ![[{{annot.imageRelativePath}}]]
{%- endif %}

{%- if annot.ocrText %}
> {{annot.ocrText}}
{%- endif %}

{%- if annot.comment %}
> - **{{annot.comment}}**
{%- endif %}
[Page {{ annot.pageLabel }}]({{ annot.desktopURI}}){% endfor %} 
{# end items loop #}

{%- endif -%} {# end color != grey #}
{%- endfor -%}
{% endpersist %}
