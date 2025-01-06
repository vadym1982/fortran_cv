! Created by  on 04.07.24.

program test
    use env
    use fortran_cv

    implicit none

    real(wp) :: points(3, 4), fov, position(3) , angles(3), uv(3, 2), t2, t1
    integer :: i

    angles = [0.0_wp * pi / 180.0_wp, 0.0_wp * pi / 180.0_wp, 15.0_wp * pi / 180.0_wp]
    position = [-10.0_wp, 0.0_wp, 0.0_wp]
    fov = 90.0_wp * pi / 180.0_wp

    call random_number(points)
    points = 0.0_wp
    points(:, 4) = 1.0_wp

    call cpu_time(t1)
    call project_points(points, size(points, dim=1), fov, position, angles, 1000.0_wp, 800.0_wp, uv)
    call cpu_time(t2)

    print "(A,F16.8)", "Time: ", t2 - t1
    do i = 1, 3
        print *, uv(i, :)
    end do

end program test