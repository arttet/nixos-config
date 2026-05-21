#!/usr/bin/env nu

use ../install/constants.nu *

export def no-ui [] {
  ($env.NIX_CONFIG_NO_UI? | default "") != ""
}

export def plain-ui [] {
  (no-ui) or ($env.NIX_CONFIG_INSTALL_PLAIN_UI? | default "") != "" or ($env.NO_COLOR? | default "") != ""
}

export def --env apply-ui-mode [no_ui: bool] {
  if $no_ui {
    $env.NIX_CONFIG_NO_UI = "1"
    $env.NIX_CONFIG_INSTALL_PLAIN_UI = "1"
  }
}

export def use-gum [] {
  not (plain-ui) and ((which gum | length) > 0)
}

export def require-ui-tools [] {
  if not (plain-ui) and ((which gum | length) == 0) {
    error make { msg: "gum is required for the interactive installer UI; set NIX_CONFIG_INSTALL_PLAIN_UI=1 for plain test output" }
  }
}

export def clear-screen-once [] {
  if not (plain-ui) and ($env.TERM? | default "") != "dumb" {
    print $"(ansi cls)(ansi home)"
  }
}

export def paint [kind: string, text: string] {
  if (plain-ui) {
    return $text
  }

  match $kind {
    "logo" => $"(ansi cyan_bold)($text)(ansi reset)"
    "heading" => $"(ansi cyan_bold)($text)(ansi reset)"
    "rule" => $"(ansi blue_dimmed)($text)(ansi reset)"
    "detail" => $"(ansi light_gray_bold)($text)(ansi reset)"
    "label" => $"(ansi blue_bold)($text)(ansi reset)"
    "value" => $"(ansi green_bold)($text)(ansi reset)"
    "prompt" => $"(ansi cyan_bold)($text)(ansi reset)"
    "success" => $"(ansi green_bold)($text)(ansi reset)"
    "warning" => $"(ansi yellow_bold)($text)(ansi reset)"
    "danger" => $"(ansi red_bold)($text)(ansi reset)"
    "muted" => $"(ansi dark_gray_bold)($text)(ansi reset)"
    "frame" => $"(ansi cyan)($text)(ansi reset)"
    _ => $text
  }
}

def gum-style [--border: string = "normal", --foreground: string = "", --border-foreground: string = "", --padding: string = "0 2", --width: string = "", text: string] {
  mut args = [ "style" "--padding" $padding ]

  if $border != "" {
    $args = ($args | append "--border" | append $border)
  }

  if $foreground != "" {
    $args = ($args | append "--foreground" | append $foreground)
  }

  if $border_foreground != "" {
    $args = ($args | append "--border-foreground" | append $border_foreground)
  }

  if $width != "" {
    $args = ($args | append "--width" | append $width)
  }

  let result = (gum ...$args $text | complete)
  if $result.exit_code == 0 {
    $result.stdout | str trim --right
  } else {
    $text
  }
}

export def render-screen [
  title: string
  rows: list<string>
  --danger
] {
  if (no-ui) {
    return ([ $title ] | append $rows | str join "\n")
  }

  if (use-gum) {
    let border_color = if $danger { "1" } else { "6" }
    let body = ([ $title "" ] | append $rows | str join "\n")
    return (gum-style --border rounded --border-foreground $border_color --padding "1 3" --width ((ui-width) | into string) $body)
  }

  let actual_width = (ui-width)
  let inner_width = $actual_width - 4
  let border_line = ("" | fill --alignment l --character '─' --width ($actual_width - 2))
  
  let frame_color = if $danger { "danger" } else { "frame" }
  let top = (paint $frame_color $"┌($border_line)┐")
  let bottom = (paint $frame_color $"└($border_line)┘")
  let rule = (paint $frame_color $"├($border_line)┤")
  
  let heading = if $danger { paint danger $title } else { paint heading $title }
  let title_len = ($title | ansi strip | str length)
  let heading_pad = $inner_width - $title_len
  let heading_padded = $heading + ("" | fill --alignment l --character " " --width $heading_pad)
  let formatted_heading = $"(paint $frame_color '│')  ($heading_padded)  (paint $frame_color '│')"
  
  let formatted_rows = ($rows | each {|row|
    let pad_len = $inner_width - ($row | ansi strip | str length)
    let padded = $row + ("" | fill --alignment l --character " " --width $pad_len)
    $"(paint $frame_color '│')  ($padded)  (paint $frame_color '│')"
  })

  let body = (
    [ $top $formatted_heading $rule ]
    | append $formatted_rows
    | append [ $bottom ]
  )

  $body | str join "\n"
}

export def print-screen [
  title: string
  rows: list<string>
  --danger
] {
  print (render-screen $title $rows --danger=$danger)
}

export def render-section [title: string, details: list<string>] {
  let colored_details = ($details | each {|d| $"  (paint detail $d)" })
  [ (paint heading $title) ...$colored_details ] | str join "\n"
}

export def print-section [title: string, details: list<string>] {
  print ""
  print (render-section $title $details)
}

export def render-kv-section [title: string, rows: list<record<label: string, value: string>>] {
  let body = (
    $rows | each {|row|
      let label = ($row.label | fill --alignment l --width (kv-label-width))
      $"  (paint label $label)  (paint value $row.value)"
    }
  )
  [ (paint heading $title) ...$body ] | str join "\n"
}

export def print-kv-section [title: string, rows: list<record<label: string, value: string>>] {
  print ""
  print (render-kv-section $title $rows)
}

export def print-danger-section [title: string, details: list<string>] {
  print ""
  print (paint danger $title)
  for detail in $details {
    print $"  (paint warning $detail)"
  }
}

export def print-error-line [message: string] {
  print $"(paint danger 'error:') ($message)"
}

export def status-text [status: string] {
  match $status {
    "ok" => (paint success "✓ ok")
    "running" => (paint warning "… running")
    "failed" => (paint danger "✗ failed")
    "pending" => (paint muted "pending")
    _ => $status
  }
}

export def render-step [index: int, total: int, label: string, status: string] {
  let step = $"(paint frame '[')(paint heading ($index | into string))(paint frame '/')(paint heading ($total | into string))(paint frame ']')"
  let padded = ($label | fill --alignment l --width 34)
  $"  ($step) ($padded) (status-text $status)"
}

export def print-step [index: int, total: int, label: string, status: string] {
  print (render-step $index $total $label $status)
}

export def prompt-text [label: string, default: string] {
  let prompt = $"(paint prompt $label) [(paint value $default)]: "
  let answer = (input $prompt | str trim)
  if $answer == "" { $default } else { $answer }
}

export def prompt-secret [label: string] {
  let value = (input --suppress-output (paint prompt $label))
  print ""
  $value
}

export def prompt-choice [label: string, options: list<string>] {
  print (paint prompt $label)
  input "> " | str trim
}
