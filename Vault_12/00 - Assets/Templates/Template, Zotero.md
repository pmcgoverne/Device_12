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
  - lit-note
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
>[!dark-grey]- Abstract
>{{abstractNote}}

{%-
    set zoteroColors = {
        "#000000": "grey",
        "#404040": "grey",
        "#808080": "grey",
        "#999999": "grey",
        "#a0a0a0": "grey",
        "#aaaaaa": "grey",
        "#5fb236": "quotes",
        "#ff6666": "quotes",
        "#ffd400": "quotes",
        "#f19837": "orange",
        "#a28ae5": "purple",
        "#e56eee": "pink",
        "#2ea8e5": "blue",
        "#3f51b5": "indigo"
    }
-%}

{%- set allAnnotations = [] -%}
{%- set newAnnotations = [] -%}

{%- for annot in annotations -%}
  {# Assign a customColor based on the hex or colorCategory #}
  {%- if annot.color in zoteroColors -%}
    {%- set customColor = zoteroColors[annot.color] -%}
  {%- elif annot.colorCategory | lower in colorHeading -%}
    {%- set customColor = annot.colorCategory | lower -%}
  {%- else -%}
    {%- set customColor = "other" -%}
  {%- endif -%}
  
  {# Push every annotation (old+new) into allAnnotations #}
  {%- set _ = allAnnotations.push({
      "annotation": annot,
      "customColor": customColor
    })
  -%}
  
  {# If annotation is new, push it into newAnnotations #}
  {%- if annot.date > lastImportDate -%}
    {%- set _ = newAnnotations.push({
        "annotation": annot,
        "customColor": customColor
      })
    -%}
  {%- endif -%}
{%- endfor %}
### Notes
---
{%- set quoteItems = allAnnotations | filterby("customColor", "startswith", "quote") %}
>[!grey]- Index{% for entry in allAnnotations -%}
{%- set annot = entry.annotation %}
{%- if annot.color == "#000000" %}
>### {{ annot.annotatedText }}
{%- elif annot.color == "#404040" %}
>#### {{ annot.annotatedText }}
  {%- elif annot.type == "text" and annot.source == "zotero" %}
> - {{ annot.comment }}
> <span style="display: inline-block; width: 100%; text-align: right;">[{{ annot.pageLabel }}]({{ annot.desktopURI }})</span>
  {%- endif -%}
{%- endfor %}


### Highlights
---
{%- set quoteItems = allAnnotations | filterby("customColor", "startswith", "quote") %}
>[!light-grey]- Quotes{% for entry in allAnnotations -%}
{%- set annot = entry.annotation %}
{%- if annot.color == "#000000" %}
>### {{ annot.annotatedText }}
{%- elif annot.color == "#404040" %}
>#### {{ annot.annotatedText }}
{%- elif annot.color == "#5fb236" %}
> - <mark style="background: #3e6e20;">{{ annot.annotatedText }}</mark>
> <span style="display: inline-block; width: 100%; text-align: right;">[{{ annot.pageLabel }}]({{ annot.desktopURI }})</span>
{%- elif annot.color == "#ff6666" %}
> - <mark style="background: #994141;">{{ annot.annotatedText }}</mark>
> <span style="display: inline-block; width: 100%; text-align: right;">[{{ annot.pageLabel }}]({{ annot.desktopURI }})</span>
{%- elif annot.color == "#ffd400" %}
> - <mark style="background: #998a26;">{{ annot.annotatedText }}</mark>
> <span style="display: inline-block; width: 100%; text-align: right;">[{{ annot.pageLabel }}]({{ annot.desktopURI }})</span>


  {%- endif -%}
{%- endfor %}

### Links
---
>[!multi-column]
>>[!orange]- Terms
{%- for entry in allAnnotations -%}
{%- set annot = entry.annotation %}
{%- if annot.color == "#404040" %}
>>---
>>###### {{ annot.annotatedText }}
>>---
{%- elif annot.color == "#f19837" %}
>>[[{{ annot.annotatedText }}]]
>><span style="display: inline-block; width: 100%; text-align: right;">[{{ annot.pageLabel }}]({{ annot.desktopURI }})</span>
  {%- endif -%}
{%- endfor %}
>
{%- set purpleItems = allAnnotations | filterby("customColor", "startswith", "purple") %}
>>[!purple]- People
{%- for entry in allAnnotations -%}
{%- set annot = entry.annotation %}
{%- if annot.color == "#404040" %}
>>---
>>###### {{ annot.annotatedText }}
>>---
{%- elif annot.color == "#a28ae5" %}
>>[[{{ annot.annotatedText }}]]
>><span style="display: inline-block; width: 100%; text-align: right;">[{{ annot.pageLabel }}]({{ annot.desktopURI }})</span>
  {%- endif -%}
{%- endfor %}
>
{%- set pinkItems = allAnnotations | filterby("customColor", "startswith", "pink") %}
>>[!pink]- Events
{%- for entry in allAnnotations -%}
  {%- set annot = entry.annotation %}
{%- if annot.color == "#404040" %}
>>---
>>###### {{ annot.annotatedText }}
>>---
{%- elif annot.color == "#e56eee" %}
>>[[{{ annot.annotatedText }}]]
>><span style="display: inline-block; width: 100%; text-align: right;">[{{ annot.pageLabel }}]({{ annot.desktopURI }})</span>
  {%- endif -%}
{%- endfor %}
>
{%- set blueItems = allAnnotations | filterby("customColor", "startswith", "blue") %}
>>[!blue]- Documents
{%- for entry in allAnnotations -%}
  {%- set annot = entry.annotation %}
{%- if annot.color == "#404040" %}
>>---
>>###### {{ annot.annotatedText }}
>>---
{%- elif annot.color == "#2ea8e5" %}
>>[[{{ annot.annotatedText }}]]
>><span style="display: inline-block; width: 100%; text-align: right;">[{{ annot.pageLabel }}]({{ annot.desktopURI }})</span>
  {%- endif -%}
{%- endfor %}
>
{%- set indigoItems = allAnnotations | filterby("customColor", "startswith", "indigo") %}
>>[!indigo]- Groups
{%- for entry in allAnnotations -%}
  {%- set annot = entry.annotation %}
{%- if annot.color == "#404040" %}
>>---
>>###### {{ annot.annotatedText }}
>>---
{%- elif annot.color == "#3f51b5" %}
>>[[{{ annot.annotatedText }}]]
>><span style="display: inline-block; width: 100%; text-align: right;">[{{ annot.pageLabel }}]({{ annot.desktopURI }})</span>
  {%- endif -%}
{%- endfor %}


