module calibration
    use env
    use fortran_cv
    use differential_evolution
    use particle_swarm
    use interfaces

    implicit none

    integer, parameter :: LOSS_EQCLIDEAN = 1
    integer, parameter :: LOSS_ATAN = 2

    interface
        function loss_function(x) result(y)
            import wp
            real(wp) :: x(:)
            real(wp) :: y
        end function loss_function
    end interface

contains

    subroutine calibrate_camera(xyz, uv, weights, width, height, lower, upper, loss, random_state, fov, position, &
            angles, k1, residual)
        !--------------------------------------------------------------------------------------------------------------
        !! Calibrate camera using Differential Evolution optimization algorithm.
        !! It is assumed that camera has no lens distortion and that optical center is at the center of the frame.
        !--------------------------------------------------------------------------------------------------------------
        real(wp), intent(in)    :: xyz(:, :)            !! Points coordinates in real world coordinate system (RW CS)
                                                        !! ((x, y, z), ...)
        real(wp), intent(in)    :: uv(:, :)             !! Points coordinates in image coordinate system in pixels
                                                        !! ((u, v), ...)
        real(wp), intent(in)    :: weights(:, :)        !! Weights factors for points deviation for u and v coordinate
                                                        !! as [[wx, wy], ...]
        real(wp), intent(in)    :: width, height        !! Width and height of the frame pixels
        real(wp), intent(in)    :: lower(8)             !! Lower bounds for fov, x, y, z, pitch, roll, yaw
        real(wp), intent(in)    :: upper(8)             !! Upper bounds for fov, x, y, z, pitch, roll, yaw
        integer, intent(in)     :: loss                 !! Loss function index
        integer, intent(in)     :: random_state         !! Random seed for random number generator
        !--------------------------------------------------------------------------------------------------------------
        real(wp), intent(out)   :: fov                  !! Camera horizontal field of view in radians
        real(wp), intent(out)   :: position(3)          !! Camera position in RW CS
        real(wp), intent(out)   :: angles(3)            !! Camera Tait Bryan angles (pitch, roll, yaw)
        real(wp), intent(out)   :: k1                   !! Radial distortion coefficient
        real(wp), intent(out)   :: residual
        !--------------------------------------------------------------------------------------------------------------
        real(wp), allocatable :: points(:, :)
        integer :: n
        real(wp), allocatable :: puv(:, :)
        real(wp) :: x_opt(7)
        type (de_solver) :: solver
        type (optimization_result) :: solution
        procedure(loss_function), pointer :: obj

        n = size(xyz, dim=1)
        allocate(points(n, 4), puv(n, 2))

        ! Preparing points array
        points(:, 1: 3) = xyz
        points(:, 4) = 1.0_wp

        ! Solving optimizatiom problem
        solver = de_solver(population=320, random_state=random_state)

        select case (loss)
            case (LOSS_EQCLIDEAN)
                obj => euclidean_loss
            case (LOSS_ATAN)
                obj => atan_loss
            case default
                error stop "Unknown loss index"
        end select

        call solver%optimize(obj, lower, upper, 2000, solution)

        ! Calibration results
        fov = solution%x(1)
        position = solution%x(2: 4)
        angles = solution%x(5: 7)
        k1 = solution%x(8)
        residual = obj(solution%x)

        contains

            function euclidean_loss(x) result(y)
                ! Equclidean distance loss
                real(wp) :: x(:)
                real(wp) :: y

                call project_points(points, size(points, dim=1), x(1), x(2: 4), x(5: 7), x(8), width, height, puv)

                y = sum(sqrt( &
                    ((uv(:, 1) - puv(:, 1)) * weights(:, 1)) ** 2 + ((uv(:, 2) - puv(:, 2)) * weights(:, 2)) ** 2 &
                ))
            end function euclidean_loss


            function atan_loss(x) result(y)
                ! Atan from euclidean distance loss (robust regression)
                real(wp) :: x(:)
                real(wp) :: y

                call project_points(points, size(points, dim=1), x(1), x(2: 4), x(5: 7), x(8), width, height, puv)

                y = sum(atan(sqrt( &
                    ((uv(:, 1) - puv(:, 1)) * weights(:, 1)) ** 2 + ((uv(:, 2) - puv(:, 2)) * weights(:, 2)) ** 2 &
                ) / width * 15.0_wp))
            end function atan_loss

    end subroutine calibrate_camera

end module calibration