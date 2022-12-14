@extends('layout.master')

@section('content')
    <div class="text-black text-2xl m-10 font-extrabold">Edit Forum Rule</div>
    <div class="overflow-y-scroll bg-stone-500 m-10 rounded-lg">

        <form class="bg-slate-200 p-5" action="{{getenv('FORUM_CLIENT')}}/updateRule" method="POST">
            @csrf
            <input type="hidden" name="forum_id" id="forum_id" value="{{$forum_id}}">
            <input type="hidden" name="forum_slug" id="forum_slug" value="{{$forum_slug}}">
            <input type="hidden" name="id" id="id" value="{{$id}}">

            <div class="p-2">
                <label class="font-extrabold" for="body">Body</label>
                <div>
                    <input type="text" name="body" id="body" value="{{$rule_content->body}}">
                </div>
            </div>

            <div class="p-2">
                <label class="font-extrabold" for="status">Status</label>
                <div>
                    <select required name="status" id="status">
                        @foreach($statuses  as $key => $value)
                            <option
                                value="{{ $key }}" {{$rule_content->status == $key  ? 'selected' : ''}}>{{ $value}}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div class="p-2">
                <label class="font-extrabold" for="author_id">author_id</label>
                <div>
                    <input type="text" name="author_id" id="author_id" value="{{$rule_content->author_id}}">
                </div>
            </div>

            <div class="p-5 text-right">
                <a class="bg-blue-800 rounded-lg p-1 text-white hover:bg-blue-600"
                   href="{{getenv('FORUM_CLIENT')}}/forum/{{$forum_id}}/{{$forum_slug}}">Cancel</a>
                <button class="btn" type="submit">Submit</button>
            </div>
        </form>
        @endsection


        @section('footer')
            <footer>© 2022 Client Forum</footer>
@endsection
