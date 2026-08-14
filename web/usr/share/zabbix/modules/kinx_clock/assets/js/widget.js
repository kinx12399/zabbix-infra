(function () {

    'use strict';


    function updateClock() {

        const now = new Date();


        /*
         * KST / Asia-Seoul
         */
        const formatter = new Intl.DateTimeFormat(
            'en-CA',
            {
                timeZone: 'Asia/Seoul',

                year: 'numeric',
                month: '2-digit',
                day: '2-digit',

                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',

                hourCycle: 'h23'
            }
        );


        const parts = {};


        formatter
            .formatToParts(now)
            .forEach((part) => {

                if (part.type !== 'literal') {
                    parts[part.type] = part.value;
                }

            });


        const time =
            `${parts.hour}:${parts.minute}`;

        const seconds =
            parts.second;

        const date =
            `${parts.year}-${parts.month}-${parts.day}`;


        document
            .querySelectorAll('.kinx-clock')
            .forEach((clock) => {


                const timeElement =
                    clock.querySelector('.kinx-clock-time');


                const secondsElement =
                    clock.querySelector('.kinx-clock-seconds');


                const dateElement =
                    clock.querySelector('.kinx-clock-date');


                if (timeElement) {
                    timeElement.textContent = time;
                }


                if (secondsElement) {
                    secondsElement.textContent = seconds;
                }


                if (dateElement) {
                    dateElement.textContent = date;
                }

            });

    }


    /*
     * 최초 즉시 갱신
     */
    updateClock();


    /*
     * 1초마다 시계 갱신
     */
    window.setInterval(
        updateClock,
        1000
    );

})();