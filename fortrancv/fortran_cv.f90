module fortran_cv
    use env

    implicit none

contains


    subroutine rodrigues(r_vec, r_mat)
        !--------------------------------------------------------------------------------------------------------------
        !! Convert rotation vector `r_vec` to rotation matrix `r_mat`
        !--------------------------------------------------------------------------------------------------------------
        real(wp), intent(in)     :: r_vec(3, 1)
        real(wp), intent(out)    :: r_mat(3, 3)
        !--------------------------------------------------------------------------------------------------------------
        real(wp) :: theta
        real(wp) :: r(3, 1)
        real(wp) :: mat(3, 3)

        theta = norm2(r_vec)

        if (abs(theta) <= eps) then
            r_mat = identity
            return
        end if

        r = r_vec / theta

        mat = reshape( &
            [0.0_wp, r(3, 1), -r(2, 1), -r(3, 1), 0.0_wp, r(1, 1), r(2, 1), -r(1, 1), 0.0_wp], &
            [3, 3] &
        )

        r_mat = cos(theta) * identity + (1.0_wp - cos(theta)) * matmul(r, transpose(r)) + sin(theta) * mat
    end subroutine rodrigues


    subroutine transformation_matrix(r_vec, t_vec, rt_mat)
        !--------------------------------------------------------------------------------------------------------------
        !! Build perspective transformation matrix `rt_mat` from rotation vector `r_vec` and translation vector `t_vec`
        !--------------------------------------------------------------------------------------------------------------
        real(wp), intent(in)    :: r_vec(3, 1)
        real(wp), intent(in)    :: t_vec(3, 1)
        real(wp), intent(out)   :: rt_mat(3, 4)
        !--------------------------------------------------------------------------------------------------------------
        call rodrigues(r_vec, rt_mat(:, 1: 3))
        rt_mat(:, 4) = t_vec(:, 1)
    end subroutine transformation_matrix


    subroutine project_points(points, n, fov, position, angles, k1, width, height, uv)
        !--------------------------------------------------------------------------------------------------------------
        !! Calculate image coordinates of points using camera parameters: fov, position, angles
        !--------------------------------------------------------------------------------------------------------------
        real(wp), intent(in)    :: points(:, :)     !! Points real world uniform coordinates ((x, y, z, 1), ...)
        integer, intent(in)     :: n                !! Number of points
        real(wp), intent(in)    :: fov              !! Camera horizontal field of view in radians
        real(wp), intent(in)    :: position(3)      !! Camera position in Real World coordinate system (x, y, z)
        real(wp), intent(in)    :: angles(3)        !! Camera Tait Bryan angles (pitch, roll, yaw)
        real(wp), intent(in)    :: k1               !! Radial distortion coefficient
        real(wp), intent(in)    :: width, height    !! Width and height of the image in pixels
        real(wp), intent(out)   :: uv(:, :)         !! Resulting points' frame coordinates ((u, v), ...)
        !--------------------------------------------------------------------------------------------------------------
        integer :: i
        real(wp) :: rt(3, 4), r0(3, 3), r1(3, 3), r2(3, 3), r3(3, 3), p(3), c, s, a, cx, cy, focal, x, y, r, dist

        r0 = reshape([0.0_wp, 0.0_wp, 1.0_wp,   1.0_wp, 0.0_wp, 0.0_wp,   0.0_wp, 1.0_wp, 0.0_wp], [3, 3])

        c = cos(-angles(3))
        s = sin(-angles(3))
        r1(1, 1) = c;       r1(1, 2) = 0.0_wp;  r1(1, 3) = s
        r1(2, 1) = 0.0_wp;  r1(2, 2) = 1.0_wp;  r1(2, 3) = 0.0_wp
        r1(3, 1) = -s;      r1(3, 2) = 0.0_wp;  r1(3, 3) = c

        c = cos(angles(1))
        s = sin(angles(1))
        r2(1, 1) = 1.0_wp;  r2(1, 2) = 0.0_wp;  r2(1, 3) = 0.0_wp
        r2(2, 1) = 0.0_wp;  r2(2, 2) = c;       r2(2, 3) = -s
        r2(3, 1) = 0.0_wp;  r2(3, 2) = s;       r2(3, 3) = c

        a = angles(2) - pi
        c = cos(a)
        s = sin(a)
        r3(1, 1) = c;       r3(1, 2) = -s;      r3(1, 3) = 0.0_wp
        r3(2, 1) = s;       r3(2, 2) = c;       r3(2, 3) = 0.0_wp
        r3(3, 1) = 0.0_wp;  r3(3, 2) = 0.0_wp;  r3(3, 3) = 1.0_wp

        r3 = matmul(r3, r2)
        r3 = matmul(r3, r1)
        r3 = matmul(r3, r0)

        rt(:, 1: 3) = r3
        rt(:, 4) = matmul(-r3, position)

        focal = width / tan(fov / 2.0_wp) / 2.0_wp
        cx = 0.5_wp * width
        cy = 0.5_wp * height

        do i = 1, n
            p = matmul(rt, points(i, :))
            x = p(1) / (p(3) + eps)
            y = p(2) / (p(3) + eps)
            r = x ** 2 + y ** 2
            dist = (1.0_wp + k1 * r)
            uv(i, 1) = focal * x * dist + cx
            uv(i, 2) = focal * y * dist + cy
        end do
    end subroutine project_points

end module fortran_cv