<?php

namespace Modules\CertificateExpiry\Actions;

use API;
use CControllerDashboardWidgetView;
use CControllerResponseData;

class WidgetView extends CControllerDashboardWidgetView {

    protected function doAction(): void {

        /*
         * LLD로 생성된 인증서 남은 일수 아이템 조회
         *
         * cert.days_left[hostname,ip,port]
         */
        $days_items = API::Item()->get([
            'output' => [
                'itemid',
                'hostid',
                'name',
                'key_',
                'lastvalue',
                'lastclock',
                'units',
                'state',
                'status'
            ],
            'selectHosts' => [
                'hostid',
                'host',
                'name',
                'status'
            ],
            'search' => [
                'key_' => 'cert.days_left['
            ],
            'startSearch' => true,
            'monitored' => true,
            'webitems' => true
        ]);

        /*
         * 실제 인증서 만료 timestamp 조회
         *
         * cert.not_after[hostname,ip,port]
         */
        $expiry_items = API::Item()->get([
            'output' => [
                'itemid',
                'hostid',
                'key_',
                'lastvalue',
                'lastclock'
            ],
            'search' => [
                'key_' => 'cert.not_after['
            ],
            'startSearch' => true,
            'monitored' => true,
            'webitems' => true
        ]);

        /*
         * host + LLD 인자를 기준으로 days_left와 not_after 연결
         */
        $expiry_map = [];

        foreach ($expiry_items as $item) {
            if ($item['lastclock'] == 0 || !is_numeric($item['lastvalue'])) {
                continue;
            }

            $suffix = substr($item['key_'], strlen('cert.not_after'));

            $expiry_map[
                $item['hostid'].'|'.$suffix
            ] = (int) $item['lastvalue'];
        }

        $rows = [];

        foreach ($days_items as $item) {

            if ($item['lastclock'] == 0 || !is_numeric($item['lastvalue'])) {
                continue;
            }

            $suffix = substr($item['key_'], strlen('cert.days_left'));

            $map_key = $item['hostid'].'|'.$suffix;

            $host_name = '';

            if (!empty($item['hosts'])) {
                $host_name = $item['hosts'][0]['name'] !== ''
                    ? $item['hosts'][0]['name']
                    : $item['hosts'][0]['host'];
            }

            /*
             * 아이템 이름:
             * CERT: domain / ip
             *
             * 화면에서는 CERT: 접두어 제거
             */
            $certificate = preg_replace(
                '/^CERT:\s*/u',
                '',
                $item['name']
            );

            $rows[] = [
                'itemid' => $item['itemid'],
                'hostid' => $item['hostid'],
                'host' => $host_name,
                'certificate' => $certificate,
                'days_left' => (float) $item['lastvalue'],
                'expires_at' => $expiry_map[$map_key] ?? null
            ];
        }

        /*
         * 실제 인증서 만료 timestamp ASC
         * 가장 먼저 만료되는 인증서가 맨 위
         */
        usort($rows, static function(array $a, array $b): int {

            if ($a['expires_at'] !== null && $b['expires_at'] !== null) {
                return $a['expires_at'] <=> $b['expires_at'];
            }

            if ($a['expires_at'] !== null) {
                return -1;
            }

            if ($b['expires_at'] !== null) {
                return 1;
            }

            return $a['days_left'] <=> $b['days_left'];
        });

        $this->setResponse(new CControllerResponseData([
            'name' => $this->getInput(
                'name',
                $this->widget->getName()
            ),
            'rows' => $rows,
            'user' => [
                'debug_mode' => $this->getDebugMode()
            ]
        ]));
    }
}