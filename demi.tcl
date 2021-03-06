#
# Fonctions de calcul des demis chemins comme une list de polygones, en effet on
# ne peut pas joindre l'ensemble des points du dessin, il faut donc utiliser une
# liste de polygones pour représenter une face du labyrinthe.
#

# direction is the index on (x, -x, y, -y)
proc demi_check_path {laby face x y direction} {

    global laby_data

    set size $laby_data($laby.size)
    set index [expr $x * $size + $y]
    set point [lindex $laby_data($laby.face.$face.grid) $index]
    if {[lindex $point $direction] == 2} {
		return 1
    }
    return 0
}

proc demi {laby face} {

    global laby_data
    global demi_path_list


    set size $laby_data($laby.size)
    set grid $laby_data($laby.face.$face.grid)

    # liste de lignes et couleur qui constituent les demis chemins
    set demi_path_list($face) [list]

    for {set x 0} {$x < $size} {incr x} {
		for {set y 0} {$y < $size} {incr y} {
			if {[demi_check_path $laby $face $x $y 0]} {
				# chaques élément de la liste est une liste de 2 points et d'une couleur
				switch $face {
					front {
						lappend demi_path_list($face) [list $x $y]
						lappend demi_path_list($face) red
					}
					side {
						lappend demi_path_list($face) [list [expr $x + 0.5] $y [expr $x + 1] $y]
						lappend demi_path_list($face) green
					}
					top {
						lappend demi_path_list($face) [list [expr $x + 0.5] $y [expr $x + 1] $y]
						lappend demi_path_list($face) red
					}
				}
			}
			if {[demi_check_path $laby $face $x $y 2]} {
				switch $face {
					front {
						lappend demi_path_list($face) [list $x [expr $y + 0.5] $x [expr $y + 1]]
						lappend demi_path_list($face) blue
					}
					side {
						lappend demi_path_list($face) [list $x $y]
						lappend demi_path_list($face) blue
					}
					top {
						lappend demi_path_list($face) [list $x $y]
						lappend demi_path_list($face) green
					}
				}
			}
		}
    }
}

proc demi_points_to_view {laby face} {

    global laby_data
    global laby_display
    global demi_path_list
    global sin_PI_6
    global cos_PI_6

    set size $laby_data($laby.size)

    # Compute the graphic unit length, use float (2.0) and round for better
    # centering of the grids.

    set grid_unit [expr round($laby_display(nb_pixel) / ($size * 2.0 + 2))]

    # Compute the display translation vectors.

    set middle  [expr $laby_display(nb_pixel) / 2]

    # Compute the translation.

    switch $face {
		front {
			set translation [list \
								 [expr $middle - ($size - 1) * $grid_unit * $cos_PI_6] \
								 [expr $middle + ($size - 1) * $grid_unit * $sin_PI_6]]
		}
		top {
			set translation [list \
								 $middle \
								 [expr $middle - ($size - 1) * 2 * $grid_unit * $sin_PI_6]]
		}
		side {
			set translation [list \
								 [expr $middle + ($size - 1) * $grid_unit * $cos_PI_6] \
								 [expr $middle + ($size - 1) * $grid_unit * $sin_PI_6]]
		}
		default {
			puts "Fatal error face $face is unknow"
			exit 1
		}
    }

    # Translation of the face origin in the display coordinates.

    set x_orig  [lindex $translation 0]
    set y_orig  [lindex $translation 1]

    # Computes the direction and size of base vectors in the display
    # coordinates.

    set dir_x [list \
				   [expr [lindex $laby_display(xy_h.$face) 0 0] * $grid_unit] \
				   [expr [lindex $laby_display(xy_h.$face) 0 1] * $grid_unit]]

    set dir_y [list \
				   [expr [lindex $laby_display(xy_h.$face) 1 0] * $grid_unit] \
				   [expr [lindex $laby_display(xy_h.$face) 1 1] * $grid_unit]]

    # Computes the new coordinates.

    set new_demi_path_list [list]

    foreach {line color} $demi_path_list($face) {

		set new_point [list]

		foreach {x y} $line {

			# Compute the point coordinates by using the xy direction
			# vector.

			set new_x [expr $x_orig + $x * [lindex $dir_x 0] + $y * [lindex $dir_x 1]]
			set new_y [expr $y_orig + $x * [lindex $dir_y 0] + $y * [lindex $dir_y 1]]

			lappend new_point $new_x $new_y
		}
		lappend new_demi_path_list $new_point $color
    }
    set demi_path_list($face) $new_demi_path_list
}

proc demi_goals_and_cursor {laby} {

    global laby_data
    global laby_display
    global demi_path_list
    global sin_PI_6
    global cos_PI_6
    global goals
    global cursor

    set size $laby_data($laby.size)

    # Compute the graphic unit length, use float (2.0) and round for better
    # centering of the grids.

    set grid_unit [expr round($laby_display(nb_pixel) / ($size * 2.0 + 2))]

    # Compute the display translation vectors.

    set middle  [expr $laby_display(nb_pixel) / 2]

    foreach face [list front side top] {

		# Compute the translation.

		switch $face {
			front {
				set translation [list \
									 [expr $middle - ($size - 1) * $grid_unit * $cos_PI_6] \
									 [expr $middle + ($size - 1) * $grid_unit *  $sin_PI_6]]
			}
			top {
				set translation [list \
									 $middle \
									 [expr $middle - ($size - 1) * 2 * $grid_unit *  $sin_PI_6]]
			}
			side {
				set translation [list \
									 [expr $middle + ($size - 1) * $grid_unit * $cos_PI_6] \
									 [expr $middle + ($size - 1) * $grid_unit * $sin_PI_6]]
			}
			default {
				puts "Fatal error face $face is unknow"
				exit 1
			}
		}

		# Translation of the face origin in the display coordinates.

		set x_orig  [lindex $translation 0]
		set y_orig  [lindex $translation 1]

		# Computes the direction and size of base vectors in the display
		# coordinates.

		set dir_x [list \
					   [expr [lindex $laby_display(xy_h.$face) 0 0] * $grid_unit] \
					   [expr [lindex $laby_display(xy_h.$face) 0 1] * $grid_unit]]

		set dir_y [list \
					   [expr [lindex $laby_display(xy_h.$face) 1 0] * $grid_unit] \
					   [expr [lindex $laby_display(xy_h.$face) 1 1] * $grid_unit]]

		# Computes the coordinates of the goal in the face.

		set x [expr $x_orig + 0 * [lindex $dir_x 0] + 0 * [lindex $dir_x 1]]
		set y [expr $y_orig + 0 * [lindex $dir_y 0] + 0 * [lindex $dir_y 1]]

		lappend goals [list $x $y [list $face]]
    }

    # the player cursor at the same coordinates regardless of the face

    set x [expr $x_orig + ($size - 1) * [lindex $dir_x 0] + ($size - 1) * [lindex $dir_x 1]]
    set y [expr $y_orig + ($size - 1) * [lindex $dir_y 0] + ($size - 1) * [lindex $dir_y 1]]

    set cursor [list $x $y [list front side top]]
}
