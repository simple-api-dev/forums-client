<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Http;

class ReportController extends Controller
{


    /**
     * Call API to upvote the specified topic
     */
    public function report($forum_id, $forum_slug, $id)
    {
        $response = Http::post(getenv('API_SITE') . '/reports/type/topic/' . $id , [
            'author_id' => "DAN",
            'type' => "Offensive",
        ]);
        if ($response->status() <> 200) {
            dd($response);
        }
        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }

    /**
     * Call API to approve the specified report
     */
    public function approveReport($forum_id, $forum_slug, $id)
    {
        $response = Http::put(getenv('API_SITE') . '/reports/' . $id , [
            'status' => "Approved",
        ]);
        if ($response->status() <> 200) {
            dd($response);
        }
        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }

    /**
     * Call API to decline the specified report
     */
    public function declineReport($forum_id, $forum_slug, $id)
    {
        $response = Http::put(getenv('API_SITE') . '/reports/' . $id , [
            'status' => "Declined",
        ]);
        if ($response->status() <> 200) {
            dd($response);
        }
        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }

    /**
     */
    public function __construct()
    {
    }
}
