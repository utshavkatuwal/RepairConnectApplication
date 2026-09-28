<?php

namespace App\Http\Requests\ApiRequests;

use Illuminate\Foundation\Http\FormRequest;

class MessageStoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool) $this->user();
    }

    public function rules(): array
    {
        return [
            'message' => ['required', 'string', 'min:1', 'max:2000'],
            'message_type' => ['sometimes', 'in:text,image'],
        ];
    }
}
