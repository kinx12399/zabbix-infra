<?php

namespace Modules\HostMonitoringStatus\Actions;

use API;
use CControllerDashboardWidgetView;
use CControllerResponseData;

class WidgetView extends CControllerDashboardWidgetView {

    protected function doAction(): void {

        /*
         * Host Monitoring Status
         *
         * key: host.monitoring.status
         *
         * 0 = Healthy
         * 1 = ICMP Problem
         * 2 = Agent Problem
         * 3 = ICMP + Agent Problem
         */

        $items = API::Item()->get([
            'output' => [
                'itemid',
                'hostid',
                'name',
                'key_',
                'lastvalue',
                'lastclock',
                'state',
                'status'
            ],
            'selectHosts' => [
                'hostid',
                'host',
                'name',
                'status'
            ],
            'filter' => [
                'key_' => 'host.monitoring.status'
            ],
            'monitored' => true
        ]);

        $summary = [
            'total' => 0,
            'healthy' => 0,
            'icmp' => 0,
            'agent' => 0,
            'down' => 0
        ];

        $problem_hosts = [];

        foreach ($items as $item) {

            /*
             * 아직 값을 한 번도 수집하지 않은 아이템은
             * 전체 집계에서 제외.
             */
            if (
                empty($item['lastclock'])
                || !is_numeric($item['lastvalue'])
            ) {
                continue;
            }

            $value = (int) $item['lastvalue'];

            /*
             * 정의된 상태값 0~3만 사용.
             */
            if ($value < 0 || $value > 3) {
                continue;
            }

            $host_name = '';

            if (!empty($item['hosts'][0])) {
                $host_name = $item['hosts'][0]['name'] !== ''
                    ? $item['hosts'][0]['name']
                    : $item['hosts'][0]['host'];
            }

            /*
             * Summary 집계.
             */
            $summary['total']++;

            switch ($value) {

                case 0:
                    $summary['healthy']++;
                    break;

                case 1:
                    $summary['icmp']++;
                    break;

                case 2:
                    $summary['agent']++;
                    break;

                case 3:
                    $summary['down']++;
                    break;
            }

            /*
             * 정상 호스트는 Problem Hosts 목록에서 제외.
             */
            if ($value !== 0) {

                switch ($value) {

                    case 1:
                        $status_text = 'ICMP 장애';
                        break;

                    case 2:
                        $status_text = 'Agent 장애';
                        break;

                    case 3:
                        $status_text = 'ICMP + Agent 장애';
                        break;

                    default:
                        $status_text = 'Unknown';
                        break;
                }

                $problem_hosts[] = [
                    'hostid' => $item['hostid'],
                    'itemid' => $item['itemid'],
                    'host' => $host_name,
                    'status' => $value,
                    'status_text' => $status_text,
                    'lastclock' => (int) $item['lastclock']
                ];
            }
        }

        /*
         * 문제 호스트 정렬:
         *
         * 3 = ICMP + Agent 장애
         * 2 = Agent 장애
         * 1 = ICMP 장애
         *
         * 동일 상태에서는 호스트 이름 순.
         */
        usort($problem_hosts, static function(array $a, array $b): int {

            if ($a['status'] !== $b['status']) {
                return $b['status'] <=> $a['status'];
            }

            return strcasecmp($a['host'], $b['host']);
        });

        $this->setResponse(new CControllerResponseData([
            'name' => $this->getInput(
                'name',
                $this->widget->getName()
            ),
            'summary' => $summary,
            'problem_hosts' => $problem_hosts,
            'user' => [
                'debug_mode' => $this->getDebugMode()
            ]
        ]));
    }
}