module calibration
    use env
    use fortran_cv
    use differential_evolution
    use particle_swarm
    use conjugate_gradient
    use simulated_annealing
    use interfaces

    implicit none

contains

    subroutine calibrate_camera(xyz, uv, width, height, lower, upper, fov, position, angles, residual)
        !--------------------------------------------------------------------------------------------------------------
        !! Calibrate camera using Differential Evolution optimization algorithm.
        !! It is assumed that camera has no lens distortion and that optical center is at the center of the frame.
        !--------------------------------------------------------------------------------------------------------------
        real(wp), intent(in)    :: xyz(:, :)            !! Points coordinates in real world coordinate system (RW CS)
                                                        !! ((x, y, z), ...)
        real(wp), intent(in)    :: uv(:, :)             !! Points coordinates in image coordinate system in pixels
                                                        !! ((u, v), ...)
        real(wp), intent(in)    :: width, height        !! Width and height of the frame pixels
        real(wp), intent(in)    :: lower(7)             !! Lower bounds for fov, x, y, z, pitch, roll, yaw
        real(wp), intent(in)    :: upper(7)             !! Upper bounds for fov, x, y, z, pitch, roll, yaw
        !--------------------------------------------------------------------------------------------------------------
        real(wp), intent(out)   :: fov                  !! Camera horizontal field of view in radians
        real(wp), intent(out)   :: position(3)          !! Camera position in RW CS
        real(wp), intent(out)   :: angles(3)            !! Camera Tait Bryan angles (pitch, roll, yaw)
        real(wp), intent(out)   :: residual
        !--------------------------------------------------------------------------------------------------------------
        real(wp), allocatable :: points(:, :)
        integer :: n
        real(wp), allocatable :: puv(:, :)
        real(wp) :: x_opt(7)
        type (de_solver) :: solver
        type (optimization_result) :: solution

        n = size(xyz, dim=1)
        allocate(points(n, 4), puv(n, 2))

        ! Preparing points array
        points(:, 1: 3) = xyz
        points(:, 4) = 1.0_wp

        ! Solving optimizatiom problem
        solver = de_solver(population=640)
        call solver%optimize(obj, lower, upper, 1500, solution)

        ! Calibration results
        fov = solution%x(1)
        position = solution%x(2: 4)
        angles = solution%x(5: 7)
        residual = obj(solution%x)

        contains

            function obj(x) result(y)
                ! Objective function
                real(wp) :: x(:)
                real(wp) :: y

                call project_points(points, size(points, dim=1), x(1), x(2: 4), x(5: 7), width, height, puv)
                y = sum(atan(sqrt((uv(:, 1) - puv(:, 1)) ** 2 + (uv(:, 2) - puv(:, 2)) ** 2) / width * 15.0_wp))
!                y = sum(sqrt((uv(:, 1) - puv(:, 1)) ** 2 + (uv(:, 2) - puv(:, 2)) ** 2))
!                y = sum(log(1.0_wp + ((uv(:, 1) - puv(:, 1)) ** 2 + (uv(:, 2) - puv(:, 2)) ** 2) / 30.0_wp ** 2))
!                y = sum(min(sqrt((uv(:, 1) - puv(:, 1)) ** 2 + (uv(:, 2) - puv(:, 2)) ** 2), 50.0_wp))
            end function obj

    end subroutine calibrate_camera

end module calibration