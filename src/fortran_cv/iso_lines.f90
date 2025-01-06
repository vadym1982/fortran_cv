module iso_lines
    use env, only: wp, pi

    implicit none

    real(wp), parameter :: TOL = 1e-6_wp

contains

    subroutine contour_prop(points, perimeter, area, x0, y0, Ix0, Iy0, Ixy0, phi, Imax, Imin)
        !--------------------------------------------------------------------------------------------------------------
        !! Calculate contour area and perimeter
        !--------------------------------------------------------------------------------------------------------------
        real(wp), intent(in)    :: points(:, :)     !! Contour points [[x, y], ...]
        real(wp), intent(out)   :: perimeter        !! Perimeter of contour
        real(wp), intent(out)   :: area             !! Area of contour
        real(wp), intent(out)   :: x0, y0           !! Coordinates of centroid
        real(wp), intent(out)   :: Ix0, Iy0, Ixy0   !! Central moments of inertia (around axes x0, y0 and mixed moment)
        real(wp), intent(out)   :: phi              !! Angle of principal axis of inertia around which principal moment
                                                    !! is maximal
        real(wp), intent(out)   :: Imax             !! Max pricipal moment of inertia
        real(wp), intent(out)   :: Imin             !! Min principal moment of inertia
        !--------------------------------------------------------------------------------------------------------------
        integer :: i, j, n
        real(wp) :: dA, Sx, Sy, Ix, Iy, Ixy, denom, tmp
        real(wp),allocatable :: x(:), y(:)

        n = size(points, dim=1)
        x = points(:, 1)
        y = points(:, 2)

        perimeter = 0.0_wp
        area = 0.0_wp
        Sx = 0.0_wp
        Sy = 0.0_wp
        x0 = 0.0_wp
        y0 = 0.0_wp
        Ix = 0.0_wp
        Iy = 0.0_wp
        Ixy = 0.0_wp

        do i = 1, n
            if (i == n) then
                j = 1
            else
                j = i + 1
            end if

            perimeter = perimeter + sqrt((x(j) - x(i)) ** 2 + (y(j) - y(i)) ** 2)
            dA = x(i) * y(j) - x(j) * y(i)
            area = area + dA
            Sx = Sx + (x(i) + x(j)) * dA
            Sy = Sy + (y(i) + y(j)) * dA
            Iy = Iy + (x(i) ** 2 + x(i) * x(j) + x(j) ** 2) * dA
            Ix = Ix + (y(i) ** 2 + y(i) * y(j) + y(j) ** 2) * dA
            Ixy = Ixy + (x(i) * y(j) + 2.0_wp * (x(i) * y(i) + x(j) * y(j)) + x(j) * y(i)) * dA
        end do

        area = area / 2.0_wp
        x0 = Sx / area / 6.0_wp
        y0 = Sy / area / 6.0_wp
        Ix = abs(Ix / 12.0_wp)
        IY = abs(Iy / 12.0_wp)
        Ixy = Ixy / 24.0_wp
        if (area < 0.0_wp) Ixy = -Ixy
        area = abs(area)
        Ix0 = Ix - area * y0 ** 2
        Iy0 = Iy - area * x0 ** 2
        Ixy0 = Ixy - area * x0 * y0
        denom = Iy0 - Ix0

        if (abs(denom / (Ix0 + Iy0)) <= TOL) then
            if (abs(Ixy0 / (Ix0 + Iy0)) <= TOL) then
                phi = 0.0_wp
            else
                phi = pi / 4.0_wp
            end if
        else
            phi = atan(2.0_wp * Ixy0 / denom) / 2.0_wp
        end if

        Imax = Ix0 * cos(phi) ** 2 + Iy0 * sin(phi) ** 2 - Ixy0 * sin(2.0_wp * phi)
        Imin = Ix0 * sin(phi) ** 2 + Iy0 * cos(phi) ** 2 + Ixy0 * sin(2.0_wp * phi)

        if (Imin > Imax) then
            tmp = Imax
            Imax = Imin
            Imin = tmp
            phi = phi + pi / 2.0_wp
            if (phi > 2 * pi) phi = phi - 2 * pi
        end if
    end subroutine contour_prop


    subroutine get_index(i, j, dir, row, col)
        !--------------------------------------------------------------------------------------------------------------
        !! Get indices of pixel for moving from pixel `i`, `j` in direction `dir`
        !--------------------------------------------------------------------------------------------------------------
        integer, intent(in)     :: i, j         !! Current pixel
        integer, intent(in)     :: dir          !! Direction: 0 - left, 1 - down, 2 - right, 3 - up
        integer, intent(out)    :: row, col     !! Pixel indices in this direction
        !--------------------------------------------------------------------------------------------------------------
        select case (dir)
            case (0)
                row = i
                col = j - 1
            case (1)
                row = i + 1
                col = j
            case (2)
                row = i
                col = j + 1
            case (3)
                row = i - 1
                col = j
        end select
    end subroutine get_index


    function rotate(dir, angle) result(new_dir)
        !--------------------------------------------------------------------------------------------------------------
        !! Rotate direction on angle
        !! Direction range from 0 to 3
        !!       3
        !!       ^
        !!  0 <  *  > 2
        !!       v
        !!       1
        !--------------------------------------------------------------------------------------------------------------
        integer, intent(in) :: dir
        integer, intent(in) :: angle
        integer             :: new_dir
        !--------------------------------------------------------------------------------------------------------------
        new_dir = dir + angle
        if (new_dir < 0) new_dir = 4 + new_dir
        if (new_dir > 3) new_dir = new_dir - 4
    end function rotate


    subroutine get_iso_lines(heatmap, value, max_cnt, cnt, ends, lines, h_max, h_mean)
        !--------------------------------------------------------------------------------------------------------------
        !! Get iso lines for heatmap == value
        !--------------------------------------------------------------------------------------------------------------
        real(wp), intent(in)        :: heatmap(:, :)
        real(wp), intent(in)        :: value
        integer, intent(in)         :: max_cnt
        integer, intent(out)        :: cnt
        integer, intent(out)        :: ends(:)
        real(wp), intent(out)       :: lines(:, :)
        real(wp), intent(out)       :: h_max(:)
        real(wp), intent(out)       :: h_mean(:)
        !--------------------------------------------------------------------------------------------------------------
        integer, allocatable :: mask(:, :)
        integer :: width, height, i, j, k, s, e, start_i, start_j, curr_i, curr_j, start_dir, dir, n, m
        integer :: min_row, max_row
        logical :: found
        real(wp) :: h1, h2, x, y, hm

        width = size(heatmap, dim=2)
        height = size(heatmap, dim=1)
        allocate(mask(height, width))
        mask = 0
        where (heatmap >= value) mask = 1
        cnt = 0
        n = 0

        contours: do while (.true.)
            found = .false.

            ! Searching for first pixel where heatmap > value
            scan: do k = 1, height
                s = findloc(mask(k, :), 1, dim=1, back=.false.)

                if (s > 0) then
                    start_i = k
                    start_j = s
                    found = .true.
                    exit scan
                end if
            end do scan

            ! Algorithm end when mask is empty
            if (.not. found) then
                exit contours
            end if

            dir = 0
            start_dir = 0
            curr_i = start_i
            curr_j = start_j
            min_row = start_i
            max_row = start_i

            pixels: do while (.true.)  ! Loop over pixels
                h1 = heatmap(curr_i, curr_j)

                directions: do while (.true.)  ! Loop over directions
                    start_dir = dir
                    call get_index(curr_i, curr_j, dir, i, j)
                    found = .false.
                    mask(curr_i, curr_j) = 2

                    ! Add new point or move to next pixel
                    if (i < 1) then            ! Top bound
                        x = j - 0.5_wp
                        y = 0.0_wp
                    else if (i > height) then  ! Bottom bound
                        x = j - 0.5_wp
                        y = 1.0_wp * width
                    else if (j < 1) then       ! Left bound
                        y = i - 0.5_wp
                        x = 0.0_wp
                    else if (j > width) then   ! Right bound
                        y = i - 0.5_wp
                        x = 1.0_wp * width
                    else
                        if (mask(i, j) == 0) then  ! Pixel with lower value then `value`
                            h2 = heatmap(i, j)

                            if (mod(dir, 2) == 0) then
                                y = i - 0.5_wp
                                x = -(value - h1) * (curr_j - j) / (h2 - h1) + curr_j - 0.5_wp
                            else
                                x = j - 0.5_wp
                                y = -(value - h1) * (curr_i - i) / (h2 - h1) + curr_i - 0.5_wp
                            end if
                        else  ! Move to next pixel
                            curr_i = i
                            curr_j = j
                            if (curr_i < min_row) min_row = curr_i
                            if (curr_i > max_row) max_row = curr_i
                            dir = rotate(dir, -2)
                            dir = rotate(dir, 1)
                            exit directions
                        end if
                    end if

                    ! Adding new point
                    n = n + 1
                    lines(n, 1) = x
                    lines(n, 2) = y
                    dir = rotate(dir, 1)

                    ! Close contour if we get to the start point and start direction
                    if ((curr_i == start_i) .and. (curr_j == start_j) .and. (dir == 0)) then
                        cnt = cnt + 1
                        ends(cnt) = n
                        exit pixels
                    end if

                    ! Close one pixel contour
                    if (dir == start_dir) then
                        cnt = cnt + 1
                        ends(cnt) = n
                        exit pixels
                    end if
                end do directions
            end do pixels

            ! Cleaning and properties calculation

            m = 0
            h_mean(cnt) = 0.0_wp
            h_max(cnt) = 0.0_wp

            do k = min_row, max_row
                s = findloc(mask(k, :), 2, dim=1, back=.false.)
                e = findloc(mask(k, :), 2, dim=1, back=.true.)
                mask(k, s: e) = 0
                m = m + (e - s + 1)
                hm = maxval(heatmap(k, s: e))
                if (hm > h_max(cnt)) h_max(cnt) = hm
                h_mean(cnt) = h_mean(cnt) + sum(heatmap(k, s: e))
            end do

            h_mean(cnt) = h_mean(cnt) / m
        end do contours

    end subroutine get_iso_lines

end module iso_lines