module env
    use iso_fortran_env, only: wp => real64

    implicit none

    real(wp), parameter :: eps = epsilon(1.0_wp)
    real(wp), parameter :: pi = atan(1.0_wp) * 4.0_wp
    real(wp), parameter :: deg = pi / 180.0_wp

    real(wp), parameter :: identity(3, 3) = reshape( &
        [1.0_wp, 0.0_wp, 0.0_wp, 0.0_wp, 1.0_wp, 0.0_wp, 0.0_wp, 0.0_wp, 1.0_wp], &
        [3, 3] &
    )

end module env