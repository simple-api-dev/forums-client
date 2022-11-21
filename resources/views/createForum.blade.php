<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Forum-Client</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    @vite('resources/css/app.css')
</head>

<body>
<div class="text-black text-2xl m-10 font-extrabold">Create Forum</div>
<div class="overflow-y-scroll bg-stone-500 m-10 rounded-lg">
    @if ($errors->any())
        <div class="alert alert-danger m-5">
            <ol>
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ol>
        </div>
    @endif

    <form class="bg-slate-100 p-5" method="POST" action="{{getenv('FORUM_CLIENT')}}/storeForum">
        @csrf

        <div class="p-2">
            <label class="font-extrabold" for="title">Title</label>
            <div>
                <input type="text" name="title" id="title" value="{{old('title')}}" size="38">
            </div>
        </div>

        <div class="p-2">
            <label class="font-extra bold" for="body">Body</label>
            <div>
                <textarea name="body" id="body" rows="2" cols="40">{{old('body')}}</textarea>
            </div>
        </div>

        <div class="p-2">
            <label class="font-extrabold" for="author_id">Author Id</label>
            <div>
                <input type="text" name="author_id" id="author_id" size="38" value="{{old('author_id')}}">
            </div>
        </div>

        <div class="p-2">
            <label class="font-extrabold" for="status">Status</label>
            <div>
                <select name="status" id="status">
                    <option value="Active">Active</option>
                    <option value="Draft">Draft</option>
                    <option value="Pending Review">Pending Review</option>
                    <option value="Locked">Locked</option>
                </select>
            </div>
        </div>

        <div class="p-5 text-right">
            <a class="bg-blue-800 rounded-lg p-1 text-white hover:bg-blue-600"
               href="{{getenv('FORUM_CLIENT')}}">Cancel</a>
            <button class="bg-blue-800 rounded-lg p-1 text-white hover:bg-blue-600" type="submit">Submit</button>
        </div>
    </form>
</div>

</body>

</html>
