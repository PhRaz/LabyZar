# laby_play.tcl

# initialisation

proc play_init {canvas} {

    puts "initialize the event interface"
    bind $canvas <ButtonPress-1> {play_ButtonPress %x %y}
    bind $canvas <ButtonRelease-1> {play_ButtonRelease %x %y}
    bind $canvas <Button1-Motion> {play_motion %x %y}

    # init pour l'utilisation des touches du clavier
    bind . <Key-Up> {play_up}
    bind . <Key-Down> {
	play_down
	puts [lindex $laby_data($play_laby.grid) [get_index_from_coord_3d $play_laby $play_cursor]]
    }
    bind . <Key-Left> {play_left}
    bind . <Key-Right> {play_right}
    bind . <Shift-Key-Left> {play_s_left}
    bind . <Shift-Key-Right> {play_s_right}
}

# event button1 pressed

proc play_ButtonPress {x y} {

    puts "proc play_ButtonPress $x $y"
}

# event button1 released

proc play_ButtonRelease {x y} {

    puts "proc play_ButtonRelease $x $y"
}

# event mouse motion while B1 pressed

proc play_motion {x y} {

    puts "proc play_motion $x $y"
}

proc play_display_path {laby cursor} {

    global laby_data
    global laby_display


    # En fonction de la présence d'un chemin sur une des 6 directions on allume
    # les segments correspondant sur les faces

    # obtenir les coord 2D à partir du cursor
    # front x' = x , y' = y
    # side  x' = z , y' = y
    # top   x' = x , y' = z
    set fx [lindex $cursor 0]
    set fy [lindex $cursor 1]
    set sx [lindex $cursor 2]
    set sy [lindex $cursor 1]
    set tx [lindex $cursor 0]
    set ty [lindex $cursor 2]

    # point de grid à la position cursor pour connaître les chemins possibles
    set position [lindex $laby_data($laby.grid) [get_index_from_coord_3d $laby $cursor]]

    # x

    if {[lindex $position 0] == 2} {

	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.front.segment.$fx.$fy.0) -fill white -width 5
	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.top.segment.$tx.$ty.0) -fill white -width 5

	lappend segment_list $laby_display($laby.front.segment.$fx.$fy.0) $laby_display(color.front)
	lappend segment_list $laby_display($laby.top.segment.$tx.$ty.0) $laby_display(color.top)
    }

    if {[lindex $position 1] == 2} {

	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.front.segment.$fx.$fy.1) -fill white -width 5
	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.top.segment.$tx.$ty.1) -fill white -width 5

	lappend segment_list $laby_display($laby.front.segment.$fx.$fy.1) $laby_display(color.front)
	lappend segment_list $laby_display($laby.top.segment.$tx.$ty.1) $laby_display(color.top)
    }

    # y

    if {[lindex $position 2] == 2} {

	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.front.segment.$fx.$fy.2) -fill white -width 5
	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.side.segment.$sx.$sy.2) -fill white -width 5

	lappend segment_list $laby_display($laby.front.segment.$fx.$fy.2) $laby_display(color.front)
	lappend segment_list $laby_display($laby.side.segment.$sx.$sy.2) $laby_display(color.side)
    }

    if {[lindex $position 3] == 2} {

	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.front.segment.$fx.$fy.3) -fill white -width 5
	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.side.segment.$sx.$sy.3) -fill white -width 5

	lappend segment_list $laby_display($laby.front.segment.$fx.$fy.3) $laby_display(color.front)
	lappend segment_list $laby_display($laby.side.segment.$sx.$sy.3) $laby_display(color.side)
    }

    # z

    if {[lindex $position 4] == 2} {

	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.side.segment.$sx.$sy.0) -fill white -width 5
	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.top.segment.$tx.$ty.2) -fill white -width 5

	lappend segment_list $laby_display($laby.side.segment.$sx.$sy.0) $laby_display(color.side)
	lappend segment_list $laby_display($laby.top.segment.$tx.$ty.2) $laby_display(color.top)
    }

    if {[lindex $position 5] == 2} {

	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.side.segment.$sx.$sy.1) -fill white -width 5
	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.top.segment.$tx.$ty.3) -fill white -width 5

	lappend segment_list $laby_display($laby.side.segment.$sx.$sy.1) $laby_display(color.side)
	lappend segment_list $laby_display($laby.top.segment.$tx.$ty.3) $laby_display(color.top)
    }

    $laby_display(canvas) lower background

    foreach s $segment_list {
	$laby_display(canvas) raise $s
    }

    $laby_display(canvas) raise point
    $laby_display(canvas) raise goal

    return $segment_list
}

proc play_down {} {

    global laby_data
    global laby_display

    global play_laby
    global play_cursor
    global play_segment_list

    # point de grid à la position cursor pour connaître les chemins possibles
    set position [lindex $laby_data($play_laby.grid) [get_index_from_coord_3d $play_laby $play_cursor]]

    if {[lindex $position 3] != 2} {
	return
    }

    # effacer les segments
    foreach {segment color} $play_segment_list {
	$laby_display(canvas) itemconfigure $segment -fill $color -width 5
    }

    # déplacer le curseur
    set play_cursor [list [lindex $play_cursor 0] [expr [lindex $play_cursor 1] - 1] [lindex $play_cursor 2]]
    for {set i 0} {$i < 5} {incr i} {
	move top 1
	$laby_display(canvas) raise goal
	update
	after 50
    }

    # afficher les nouveaux segments
    set play_segment_list [play_display_path $play_laby $play_cursor]
}

proc play_up {} {

    global laby_data
    global laby_display

    global play_laby
    global play_cursor
    global play_segment_list

    # point de grid à la position cursor pour connaître les chemins possibles
    set position [lindex $laby_data($play_laby.grid) [get_index_from_coord_3d $play_laby $play_cursor]]

    if {[lindex $position 2] != 2} {
	return
    }

    # effacer les segments
    foreach {segment color} $play_segment_list {
	$laby_display(canvas) itemconfigure $segment -fill $color -width 5
    }

    # déplacer le curseur
    set play_cursor [list [lindex $play_cursor 0] [expr [lindex $play_cursor 1] + 1] [lindex $play_cursor 2]]
    for {set i 0} {$i < 5} {incr i} {
	move top -1
	$laby_display(canvas) raise goal
	update
	after 50
    }

    # afficher les nouveaux segments
    set play_segment_list [play_display_path $play_laby $play_cursor]
}

proc play_left {} {

    global laby_data
    global laby_display

    global play_laby
    global play_cursor
    global play_segment_list

    # point de grid à la position cursor pour connaître les chemins possibles
    set position [lindex $laby_data($play_laby.grid) [get_index_from_coord_3d $play_laby $play_cursor]]

    if {[lindex $position 4] != 2} {
	return
    }

    # effacer les segments
    foreach {segment color} $play_segment_list {
    	$laby_display(canvas) itemconfigure $segment -fill $color -width 5
    }

    # déplacer le curseur
    set play_cursor [list [lindex $play_cursor 0] [lindex $play_cursor 1] [expr [lindex $play_cursor 2] + 1]]
    for {set i 0} {$i < 5} {incr i} {
	move front -1
	$laby_display(canvas) raise goal
	update
	after 50
    }

    # afficher les nouveaux segments
    set play_segment_list [play_display_path $play_laby $play_cursor]
}

proc play_right {} {

    global laby_data
    global laby_display

    global play_laby
    global play_cursor
    global play_segment_list

    # point de grid à la position cursor pour connaître les chemins possibles
    set position [lindex $laby_data($play_laby.grid) [get_index_from_coord_3d $play_laby $play_cursor]]

    if {[lindex $position 0] != 2} {
	return
    }

    # effacer les segments
    foreach {segment color} $play_segment_list {
	$laby_display(canvas) itemconfigure $segment -fill $color -width 5
    }

    # déplacer le curseur
    set play_cursor [list [expr [lindex $play_cursor 0] + 1] [lindex $play_cursor 1] [lindex $play_cursor 2]]
    for {set i 0} {$i < 5} {incr i} {
	move side -1
	$laby_display(canvas) raise goal
	update
	after 50
    }

    # afficher les nouveaux segments
    set play_segment_list [play_display_path $play_laby $play_cursor]
}

proc play_s_left {} {

    global laby_data
    global laby_display

    global play_laby
    global play_cursor
    global play_segment_list

    # point de grid à la position cursor pour connaître les chemins possibles
    set position [lindex $laby_data($play_laby.grid) [get_index_from_coord_3d $play_laby $play_cursor]]

    if {[lindex $position 1] != 2} {
	return
    }

    # effacer les segments
    foreach {segment color} $play_segment_list {
	$laby_display(canvas) itemconfigure $segment -fill $color -width 5
    }

    # déplacer le curseur
    set play_cursor [list [expr [lindex $play_cursor 0] - 1] [lindex $play_cursor 1] [lindex $play_cursor 2]]
    for {set i 0} {$i < 5} {incr i} {
	move side 1
	$laby_display(canvas) raise goal
	update
	after 50
    }

    # afficher les nouveaux segments
    set play_segment_list [play_display_path $play_laby $play_cursor]
}

proc play_s_right {} {

    global laby_data
    global laby_display

    global play_laby
    global play_cursor
    global play_segment_list

    # point de grid à la position cursor pour connaître les chemins possibles
    set position [lindex $laby_data($play_laby.grid) [get_index_from_coord_3d $play_laby $play_cursor]]

    if {[lindex $position 5] != 2} {
     	return
    }

    # effacer les segments
    foreach {segment color} $play_segment_list {
	$laby_display(canvas) itemconfigure $segment -fill $color -width 5
    }

    # déplacer le curseur
    set play_cursor [list [lindex $play_cursor 0] [lindex $play_cursor 1] [expr [lindex $play_cursor 2] - 1]]
    for {set i 0} {$i < 5} {incr i} {
	move front 1
	$laby_display(canvas) raise goal
	update
	after 50
    }

    # afficher les nouveaux segments
    set play_segment_list [play_display_path $play_laby $play_cursor]
}
