<?php

namespace App\Http\Controllers;


class ReportController extends Controller
{
    /**
     * Call API to upvote the specified topic
     */
    public function report($forum_id, $forum_slug, $id)
    {
        $response = $this->apirequest->post(getenv('API_SITE') . '/reports/type/topic/' . $id, [
            'author_id' => "DAN",
            'type' => "Offensive",
        ]);
        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }

    /**
     * Call API to approve the specified report
     */
    public function approveReport($forum_id, $forum_slug, $id)
    {
        $response = $this->apirequest->put(getenv('API_SITE') . '/reports/' . $id, [
            'status' => "Approved",
        ]);
        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }

    /**
     * Call API to decline the specified report
     */
    public function declineReport($forum_id, $forum_slug, $id)
    {
        $response = $this->apirequest->put(getenv('API_SITE') . '/reports/' . $id, [
            'status' => "Declined",
        ]);
        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }
}
