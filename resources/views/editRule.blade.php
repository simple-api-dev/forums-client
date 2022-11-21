@extends('layout.master')

@section('content')
<h3>Edit Rule</h3>
<form action="{{getenv('FORUM_CLIENT')}}/updateRule" method="POST">
    @csrf
    <input type="hidden" name="forum_id" id="forum_id" value="{{$forum_id}}">
    <input type="hidden" name="forum_slug" id="forum_slug" value="{{$forum_slug}}">
    <input type="hidden" name="id" id="id" value="{{$id}}">

    <div>
        <label for="body">Body</label>
        <input type="text" name="body" id="body" value="{{$rule_content->body}}">
    </div>

    <div>
        <label for="status">Status</label>
        <select required name="status" id="status">
            @foreach($statuses  as $key => $value)
                <option
                    value="{{ $key }}" {{$rule_content->status == $key  ? 'selected' : ''}}>{{ $value}}</option>
            @endforeach
        </select>
    </div>

    <div>
        <label for="author_id">author_id</label>
        <input type="text" name="author_id" id="author_id" value="{{$rule_content->author_id}}">
    </div>

    <input type="reset" name="reset" value="Reset">
    <input type="submit" name="submit" value="Submit">
</form>
@endsection


@section('footer')
    <footer>© 2022 Client Forum</footer>
@endsection
