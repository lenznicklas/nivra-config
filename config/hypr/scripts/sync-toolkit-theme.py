#!/usr/bin/env python3
"""Generate GTK/Qt palettes and Fortress Kvantum assets from the active shell theme."""
from pathlib import Path
import colorsys
import configparser
import io
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]

def ini():
    p = configparser.ConfigParser(interpolation=None, strict=False)
    p.optionxform = str
    return p

def write(path, text):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists() or path.read_text() != text:
        path.write_text(text)

def dump(p):
    s = io.StringIO(); p.write(s, space_around_delimiters=False)
    return s.getvalue()

def generate():
    qml = (ROOT / 'quickshell/fortress/modules/Theme.qml').read_text()
    palette = {}
    for name, args in re.findall(r'property color (\w+): Qt\.rgba\(([^)]+)\)', qml):
        def num(v):
            a = v.strip().split('/')
            return float(a[0]) / float(a[1]) if len(a) == 2 else float(a[0])
        palette[name] = tuple(num(v) for v in args.split(','))
    def rgb(name): return palette[name][:3]
    def mix(a, b, weight): return tuple(x * (1-weight) + y * weight for x,y in zip(a,b))
    def hexc(c): return '#' + ''.join(f'{round(x*255):02x}' for x in c[:3])
    bg = rgb('bg'); accent = rgb('accent'); text = rgb('text')
    c = {k:hexc(v) for k,v in palette.items()}
    c['surface'] = hexc(mix(bg, accent, palette['chipSurface'][3]))
    c['secondary'] = hexc(mix(bg, rgb('muted'), palette['muted'][3]))
    c['selection'] = hexc(mix(bg, accent, palette['chipHover'][3]))
    c['border'] = hexc(mix(bg, rgb('accentSoft'), palette['chipBorder'][3]))
    c['mutedText'] = hexc(mix(bg, text, palette['textMuted'][3]))
    font = re.search(r'property string fontName: "([^"]+)"', qml)[1]
    radius = int(re.search(r'property int chipRadius: (\d+)', qml)[1])
    outer = int(re.search(r'property int barRadius: (\d+)', qml)[1])
    defs = '\n'.join(f'@define-color fortress_{k} {v};' for k,v in c.items()) + '\n'
    write('ui-theme/colors.css', '/* Generated from Quickshell Theme.qml. */\n'+defs)
    for version in (3,4):
        p = ini(); path=ROOT/f'gtk-{version}.0/settings.ini'; p.read(path)
        if not p.has_section('Settings'): p.add_section('Settings')
        for key,value in {'gtk-theme-name':'Adwaita-dark','gtk-application-prefer-dark-theme':'true',
                          'gtk-icon-theme-name':'Adwaita','gtk-cursor-theme-name':'Adwaita',
                          'gtk-cursor-theme-size':'24','gtk-font-name':font+' 10'}.items():
            p['Settings'][key]=value
        if version == 3:
            p['Settings']['gtk-dialogs-use-header']='true'
        write(f'gtk-{version}.0/settings.ini',dump(p))
        template = (ROOT / f'ui-theme/filechooser-gtk{version}.css.in').read_text()
        write(f'gtk-{version}.0/filechooser.css', template.replace('RADIUS',str(radius)).replace('OUTER',str(outer)))
    # Named colors used by Adwaita GTK3 and non-libadwaita GTK4 widgets.
    common = '''@import url("../ui-theme/colors.css");
@define-color theme_bg_color @fortress_bg;
@define-color theme_fg_color @fortress_text;
@define-color theme_base_color @fortress_bg;
@define-color theme_text_color @fortress_text;
@define-color theme_selected_bg_color @fortress_selection;
@define-color theme_selected_fg_color @fortress_text;
@define-color insensitive_bg_color @fortress_surface;
@define-color insensitive_fg_color @fortress_mutedText;
@define-color insensitive_base_color @fortress_bg;
@define-color theme_unfocused_bg_color @fortress_bg;
@define-color theme_unfocused_fg_color @fortress_mutedText;
@define-color theme_unfocused_base_color @fortress_bg;
@define-color theme_unfocused_text_color @fortress_text;
@define-color theme_unfocused_selected_bg_color @fortress_selection;
@define-color theme_unfocused_selected_fg_color @fortress_text;
@define-color borders @fortress_border;
@define-color unfocused_borders @fortress_border;
@define-color warning_color @fortress_accentSoft;
@define-color error_color @fortress_danger;
@define-color success_color @fortress_accentSoft;
'''
    gtk3 = '''
/* Work surfaces stay opaque. Compositor blur is not faked inside app content. */
.background { background-color: @fortress_bg; color: @fortress_text; }
headerbar, toolbar, .primary-toolbar, statusbar {
  background-color: @fortress_surface; background-image: none;
  color: @fortress_text; border-color: @fortress_border; box-shadow: none;
}
headerbar { min-height: 36px; padding: 4px 8px; }
button, entry, spinbutton, combobox > box > button {
  background-image: none; background-color: @fortress_surface;
  color: @fortress_text; border: 1px solid @fortress_border;
  border-radius: RADIUSpx; box-shadow: none; text-shadow: none;
  min-height: 24px; padding: 4px 10px;
}
button.flat, button.sidebar-button { background: transparent; border-color: transparent; }
button:hover, button.flat:hover { background: @fortress_selection; border-color: @fortress_border; }
button:active, button:checked { background: @fortress_selection; border-color: @fortress_accent; }
button.suggested-action { background: @fortress_accent; color: @fortress_bg; border-color: @fortress_accent; }
button.suggested-action:hover { background: @fortress_accentSoft; }
button.destructive-action { color: @fortress_danger; }
entry { background-color: @fortress_bg; caret-color: @fortress_accent; }
entry:focus, spinbutton:focus { border-color: @fortress_accent; box-shadow: inset 0 0 0 1px alpha(@fortress_accent,0.18); }
entry selection, textview text selection { background: @fortress_selection; color: @fortress_text; }
entry image, label.dim-label { color: @fortress_mutedText; }
button:disabled, entry:disabled { color: @fortress_mutedText; background-color: @fortress_bg; }
view, treeview.view, iconview, textview text, list, list row { background-color: @fortress_bg; color: @fortress_text; }
.view:selected, treeview.view:selected, iconview:selected, list row:selected {
  background-color: @fortress_selection; color: @fortress_text;
}
.view:hover:not(:selected), list row:hover:not(:selected) { background-color: @fortress_surface; }
placessidebar, placessidebar viewport, placessidebar list, placessidebar row, .sidebar {
  background-color: @fortress_surface; color: @fortress_text;
}
placessidebar row { padding: 4px 6px; border-radius: RADIUSpx; }
placessidebar row:selected { background: @fortress_selection; color: @fortress_accentSoft; }
menu, .menu, popover.background {
  background-color: @fortress_surface; color: @fortress_text;
  border: 1px solid @fortress_border; border-radius: OUTERpx;
  padding: 4px; box-shadow: 0 5px 16px alpha(black,0.22);
}
menuitem { min-height: 22px; padding: 3px 8px; border-radius: 6px; color: @fortress_text; }
menuitem:hover { background-color: @fortress_selection; color: @fortress_accentSoft; }
menuitem:disabled { color: @fortress_mutedText; }
tooltip, tooltip.background { background: @fortress_secondary; color: @fortress_text; border: 1px solid @fortress_border; border-radius: RADIUSpx; }
notebook > header { background: @fortress_surface; border-color: @fortress_border; }
notebook > header tab:checked { background: @fortress_selection; box-shadow: inset 0 -2px @fortress_accent; }
check, radio { background-image: none; background-color: @fortress_surface; border-color: @fortress_border; box-shadow: none; }
check:checked, radio:checked { background-color: @fortress_accent; color: @fortress_bg; border-color: @fortress_accent; }
scale trough, progressbar trough { background: @fortress_secondary; border-color: @fortress_border; }
scale highlight, progressbar progress { background: @fortress_accent; border-color: @fortress_accent; }
separator { background: @fortress_border; min-height: 1px; min-width: 1px; }
'''
    scroll = '''
scrollbar, scrollbar trough { background: transparent; border: none; box-shadow: none; }
scrollbar slider { background: alpha(@fortress_text,0.24); border: none; border-radius: 8px; min-width: 6px; min-height: 6px; margin: 2px; }
scrollbar.vertical slider { min-height: 32px; }
scrollbar.horizontal slider { min-width: 32px; }
scrollbar slider:hover { background: alpha(@fortress_accentSoft,0.7); }
scrollbar slider:active { background: @fortress_accent; }
'''
    write('gtk-3.0/gtk.css', '/* Fortress GTK3; generated by sync-toolkit-theme.py. */\n'+common+gtk3.replace('RADIUS',str(radius)).replace('OUTER',str(outer))+scroll+'\n@import url("filechooser.css");\n')
    adw = {
        'window_bg_color':'bg','window_fg_color':'text','view_bg_color':'bg','view_fg_color':'text',
        'headerbar_bg_color':'surface','headerbar_fg_color':'text','headerbar_backdrop_color':'surface',
        'headerbar_border_color':'border','card_bg_color':'surface','card_fg_color':'text',
        'dialog_bg_color':'surface','dialog_fg_color':'text','popover_bg_color':'surface','popover_fg_color':'text',
        'sidebar_bg_color':'surface','sidebar_fg_color':'text','sidebar_backdrop_color':'surface',
        'secondary_sidebar_bg_color':'secondary','secondary_sidebar_fg_color':'text',
        'secondary_sidebar_backdrop_color':'secondary','thumbnail_bg_color':'surface','thumbnail_fg_color':'text',
        'accent_color':'accentSoft','accent_bg_color':'accent','accent_fg_color':'bg',
        'destructive_color':'danger','destructive_bg_color':'danger','destructive_fg_color':'bg',
        'warning_color':'accentSoft','warning_bg_color':'accentSoft','warning_fg_color':'bg',
        'success_color':'accentSoft','success_bg_color':'selection','success_fg_color':'text',
        'error_color':'danger','error_bg_color':'danger','error_fg_color':'bg',
    }
    gtk4 = ''.join(f'@define-color {k} @fortress_{v};\n' for k,v in adw.items() if k not in ('warning_color','error_color','success_color'))
    gtk4 += '\n/* Current libadwaita uses public CSS variables; retain named colors for older apps. */\n:root {\n'
    gtk4 += ''.join(f'  --{k.replace("_","-")}: @fortress_{v};\n' for k,v in adw.items())
    gtk4 += '  --border-color: @fortress_border;\n  --shade-color: alpha(black,0.20);\n}\n'
    gtk4 += '''
/* Preserve libadwaita layout, state indicators, switches and accessibility. */
window.background { background-color: @fortress_bg; color: @fortress_text; }
popover > contents { border-color: @fortress_border; border-radius: OUTERpx; }
entry, button:not(.flat):not(.circular) { border-radius: RADIUSpx; }
entry:focus-within { outline-color: @fortress_accent; }
selection { background-color: @fortress_selection; color: @fortress_text; }
'''.replace('RADIUS',str(radius)).replace('OUTER',str(outer))
    # Preserve the existing file-manager-specific overrides, loaded after toolkit rules.
    write('gtk-4.0/gtk.css', '/* Fortress GTK4/libadwaita; generated by sync-toolkit-theme.py. */\n'+common+gtk4+scroll+'\n@import url("filechooser.css");\n@import url("../strata/style.css");\n')
    if '--gtk-only' in sys.argv:
        print('Generated Fortress GTK3/GTK4 including dedicated file chooser styles.')
        return
    # qt6ct on this Arch installation advertises BOTH qt6ct and qt5ct plugin keys.
    # A single QT_QPA_PLATFORMTHEME=qt5ct therefore serves both Qt versions.
    role_colors=[c['text'],c['surface'],c['secondary'],c['border'],c['bg'],c['secondary'],c['text'],c['text'],c['text'],c['bg'],c['bg'],c['secondary'],c['selection'],c['text'],c['accentSoft'],c['accent'],c['surface'],c['bg'],c['surface'],c['text'],c['mutedText'],c['accent']]
    for version in (5,6):
        color_path=f'qt{version}ct/colors/Fortress.conf'
        scheme=ini(); scheme['ColorScheme']={}
        for group in ('active','inactive','disabled'):
            roles=role_colors.copy()
            if group=='disabled':
                for idx in (0,6,8,13,19,20): roles[idx]=c['mutedText']
            scheme['ColorScheme'][group+'_colors']=', '.join('#ff'+v[1:] for v in roles)
        write(color_path,dump(scheme))
        p=ini(); p.read(ROOT/f'qt{version}ct/qt{version}ct.conf')
        for section in ('Appearance','Fonts','Interface'):
            if section not in p: p[section]={}
        p['Appearance'].update({'style':'kvantum','icon_theme':'Adwaita','custom_palette':'true',
                               'color_scheme_path':str(ROOT/color_path),'standard_dialogs':'xdgdesktopportal'})
        # QSettings accepts a serialized QFont string in both Qt versions.
        p['Fonts'].update({'general':f'"{font},10,-1,5,50,0,0,0,0,0"','fixed':f'"{font},10,-1,5,50,0,0,0,0,0"'})
        p['Interface'].update({'menus_have_icons':'true','dialog_buttons_have_icons':'1','stylesheets':'@Invalid()'})
        write(f'qt{version}ct/qt{version}ct.conf',dump(p))
    kvantum(c,radius,outer)
    print('Generated Fortress GTK3/GTK4, Qt5/Qt6 and Kvantum from Quickshell Theme.qml.')

def kvantum(c,radius,outer):
    base=ROOT/'ui-theme/kvantum-base'
    p=ini(); p.read(base/'base.kvconfig')
    p['%General'].update({'author':'Fortress local theme; base asset grammar by Tsu Jan',
                         'comment':'Quickshell Fortress palette, flat SVG controls, compact spacing',
                         'scroll_width':'10','scroll_arrows':'false','scroll_min_extent':'36',
                         'layout_spacing':'8','toolbar_item_spacing':'4','toolbar_icon_size':'16',
                         'translucent_windows':'false','blurring':'false','popup_blurring':'false',
                         'menu_shadow_depth':'4','tooltip_shadow_depth':'3','no_inactiveness':'true',
                         'merge_menubar_with_toolbar':'false','spread_menuitems':'false'})
    roles={'window.color':'bg','inactive.window.color':'bg','base.color':'bg','inactive.base.color':'bg',
           'alt.base.color':'surface','inactive.alt.base.color':'surface','button.color':'surface',
           'light.color':'secondary','mid.light.color':'secondary','dark.color':'bg','mid.color':'border',
           'highlight.color':'selection','inactive.highlight.color':'selection','text.color':'text',
           'window.text.color':'text','inactive.text.color':'text','inactive.window.text.color':'text',
           'button.text.color':'text','disabled.text.color':'mutedText','tooltip.text.color':'text',
           'highlight.text.color':'text','link.color':'accentSoft','link.visited.color':'accent',
           'progress.indicator.text.color':'text'}
    for key,role in roles.items(): p['GeneralColors'][key]=c[role]
    for section in p.sections():
        if section in ('%General','GeneralColors','Hacks'): continue
        for key in p[section]:
            if key.startswith('text.') and key.endswith('.color'):
                p[section][key]=c['mutedText'] if 'inactive' in key else c['text']
            if key=='text.shadow': p[section][key]='false'
    p['Hacks'].update({'transparent_dolphin_view':'false','transparent_pcmanfm_sidepane':'false',
                       'force_size_grip':'false','respect_darkness':'true'})
    # Keep a complete, tested SVG indicator grammar, recolored from the local palette.
    ET.register_namespace('', 'http://www.w3.org/2000/svg')
    ET.register_namespace('xlink', 'http://www.w3.org/1999/xlink')
    svg=ET.parse(base/'base.svg').getroot()
    def remap(match):
        value=match[0][1:]
        if len(value)==3: value=''.join(x*2 for x in value)
        if len(value)!=6: return match[0]
        r,g,b=[int(value[i:i+2],16)/255 for i in (0,2,4)]
        h,s,v=colorsys.rgb_to_hsv(r,g,b)
        if s>0.25: return c['selection']
        if v<0.04: return '#000000'
        if v<0.17: return c['bg']
        if v<0.25: return c['surface']
        if v<0.39: return c['secondary']
        if v<0.62: return c['border']
        if v<0.82: return c['mutedText']
        return c['text']
    for element in svg.iter():
        for key,val in list(element.attrib.items()):
            element.set(key,re.sub(r'#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b',remap,val))
    NS='{http://www.w3.org/2000/svg}'
    def rect(parent,x,y,w,h,fill):
        ET.SubElement(parent,NS+'rect',{'x':str(x),'y':str(y),'width':str(w),'height':str(h),'fill':fill})
    # Native nine-slice controls: true 8/12px corners, flat surfaces, one-pixel borders.
    def sliced(name,state,fill,border,r):
        root=ET.SubElement(svg,NS+'g',{'id':name+'-'+state}); rect(root,0,0,16,16,fill)
        for edge in ('top','bottom','left','right'):
            group=ET.SubElement(svg,NS+'g',{'id':name+'-'+state+'-'+edge})
            horizontal=edge in ('top','bottom')
            w,h=(16,r) if horizontal else (r,16)
            rect(group,0,0,w,h,fill)
            rect(group,0 if edge!='right' else r-1,0 if edge!='bottom' else r-1,w if horizontal else 1,1 if horizontal else h,border)
        for corner,angle in [('topleft',0),('topright',90),('bottomright',180),('bottomleft',270)]:
            group=ET.SubElement(svg,NS+'g',{'id':name+'-'+state+'-'+corner})
            inner=ET.SubElement(group,NS+'g',{'transform':f'rotate({angle},{r/2},{r/2})'})
            ET.SubElement(inner,NS+'path',{'d':f'M {r} 0 A {r} {r} 0 0 0 0 {r} L {r} {r} Z','fill':border})
            ET.SubElement(inner,NS+'path',{'d':f'M {r} 1 A {r-1} {r-1} 0 0 0 1 {r} L {r} {r} Z','fill':fill})
    widgets=[('PanelButtonCommand','fortress-button',radius,'surface'),('LineEdit','fortress-entry',radius,'bg'),
             ('Menu','fortress-menu',outer,'surface'),('ToolTip','fortress-tooltip',radius,'secondary'),
             ('MenuItem','fortress-item',6,'surface'),
             ('ComboBox','fortress-combo',radius,'surface'),
             ('Slider','fortress-track',2,'secondary'),
             ('Progressbar','fortress-trough',2,'secondary'),
             ('ProgressbarContents','fortress-progress',2,'accent'),
             ('ScrollbarSlider','fortress-scroll',3,'secondary'),
             ('ScrollbarTransientSlider','fortress-transient-scroll',3,'secondary')]
    for section,name,r,normal in widgets:
        if section not in p: p[section]={}
        for key in ('frame.element','frame.expandedElement','interior.element'): p[section][key]=name
        for edge in ('top','bottom','left','right'): p[section]['frame.'+edge]=str(r)
        p[section].update({'frame':'true','interior':'true','text.shadow':'false'})
        for state in ('normal','focused','pressed','toggled'):
            fill=c[normal] if state=='normal' else c['selection']
            if section in ('Slider','Progressbar'): fill=c['secondary']
            if section=='ProgressbarContents': fill=c['accent']
            if section in ('ScrollbarSlider','ScrollbarTransientSlider') and state!='normal': fill=c['accentSoft']
            border=c['accent'] if state in ('pressed','toggled') or (section=='LineEdit' and state=='focused') else c['border']
            if section in ('MenuItem','Slider','Progressbar','ProgressbarContents','ScrollbarSlider','ScrollbarTransientSlider'): border=fill
            for suffix in ('','-inactive'): sliced(name,state+suffix,fill,border,r)
    p['SliderCursor'].update({'frame':'false','interior':'true','interior.element':'fortress-knob'})
    for state in ('normal','focused','pressed','toggled'):
        for suffix in ('','-inactive'):
            group=ET.SubElement(svg,NS+'g',{'id':'fortress-knob-'+state+suffix})
            ET.SubElement(group,NS+'circle',{'cx':'8','cy':'8','r':'7','fill':c['accentSoft'] if state=='focused' else c['accent'],'stroke':c['bg'],'stroke-width':'1'})
    p['PanelButtonCommand'].update({'text.margin.top':'0','text.margin.bottom':'0','text.margin.left':'2','text.margin.right':'2','min_height':'0'})
    p['LineEdit'].update({'text.margin.top':'0','text.margin.bottom':'0','text.margin.left':'2','text.margin.right':'2'})
    p['MenuItem'].update({'text.margin.top':'0','text.margin.bottom':'0','text.margin.left':'6','text.margin.right':'6'})
    write('Kvantum/Fortress/Fortress.kvconfig',dump(p))
    write('Kvantum/Fortress/Fortress.svg',ET.tostring(svg,encoding='unicode'))
    write('Kvantum/kvantum.kvconfig','[General]\ntheme=Fortress\n')

if __name__=='__main__': generate()
