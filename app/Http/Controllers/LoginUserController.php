<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules;


class LoginUserController extends Controller
{
    public function create()
    {
        return view('auth.login');
    }


    public function store(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'email' => ['required', 'string', 'email', 'max:255'],
            'password' => ['required', Rules\Password::defaults()],
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $response = HTTP::post(getenv('AUTH_SITE') . '/login/?apikey=' . getenv('AUTH_APIKEY'), [
            'integration_id' => getenv('INTEGRATION_ID'),
            'email' => $request_data['email'],
            'password' => $request_data['password'],
        ]);

        if (!$response->successful()) {
            $response = json_decode($response);
            $validate->getMessageBag()->add('message', $response->message);
            return back()->withErrors($validate->errors())->withInput();
        }

        $response = json_decode($response);
        $request->session()->regenerate();
        $request->session()->put('token', $response->token);
        $request->session()->put('author_id', $response->username);

        return redirect(getenv('FORUM_CLIENT'));
    }


    public function destroy(Request $request)
    {
        Http::post(getenv('AUTH_SITE') . '/logout/?apikey=' . getenv('AUTH_APIKEY'), [
            'token' => $request->session()->get('key'),
        ]);

        $request->session()->flush();
        $request->session()->regenerate();
        return redirect(getenv('FORUM_CLIENT'));
    }
}
