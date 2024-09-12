namespace Horis.TimeUtil {
    private int get_last_day_of_month(int year, int month) {
        if (month == 2) {
            return (is_leap_year(year)) ? 29 : 28;
        }

        if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }

        return 31;
    }

    private bool is_leap_year(int year) {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    }

    private int get_day_of_week(DateTime date) {
        return (int) date.get_day_of_week(); // Returns 7 for Sunday, 1 for Monday, etc.
    }

    private string format_date(DateTime date) {
        return date.format("%Y-%m-%d");
    }

    private DateTime create_date(int year, int month, int day) {
        return new DateTime.local(year, month, day, 0, 0, 0);
    }
}