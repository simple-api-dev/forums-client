<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules;

class RegisteredUserController extends Controller
{
    public function create()
    {
        return view('auth.register');
    }


    public function store(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255'],
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $response = Http::timeout(3)->post(getenv('AUTH_SITE') . '/register/' . '?apikey=' . getenv('AUTH_APIKEY'), [
            'integration_id' => '205',
            'name' => $request_data['name'],
            'email' => $request_data['email'],
            'password' => $request_data['password'],
        ]);

        if (!$response->successful()) {
            $msg = (string) $response->getBody();
            $validate->getMessageBag()->add($response->getStatusCode(), $msg);
            return back()->withErrors($validate->errors())->withInput();
        }

        $message = $response->getBody();
        return view('auth.registerSuccessful', compact('message'));
    }
}
