#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <onnxruntime_c_api.h>

#define MAX_MODELS 10
#define MAX_INPUTS 10
#define MAX_OUTPUTS 10

typedef struct {
    char name[50];
    int64_t shape[4];
    int shape_len;
    int n_elem;
    ONNXTensorElementDataType dtype;
} TensorInfo;

typedef struct {
    char model_path[150];
    TensorInfo inputs[MAX_INPUTS];
    int num_inputs;
    TensorInfo outputs[MAX_OUTPUTS];
    int num_outputs;
    float *input_data[MAX_INPUTS];
    float *output_data[MAX_OUTPUTS];
} ModelInfo;

ModelInfo models[MAX_MODELS];
size_t num_models = 8;

#include "model_details.h"
// Global variables for the ONNX Runtime environment, session, and input/output tensors
OrtEnv* env;
OrtSession* sessions[MAX_MODELS];
OrtSessionOptions* session_options;
OrtMemoryInfo* memory_info;
OrtStatus *status;
OrtApi *g_api;

void set_input_data_(int *model_index, int *input_index, float *data) {
    ModelInfo *model = &models[*model_index];
    int i;
    for (i = 0; i < model->inputs[*input_index].n_elem; i++) {
        model->input_data[*input_index][i] = data[i];
    }
}

void get_output_data_(int *model_index, int *output_index, float *data) {
    ModelInfo *model = &models[*model_index];
    int i;
    //printf("output index %d\n", *output_index);
    //printf("output n_elem %d\n", model->outputs[*output_index].n_elem);
    if (model->output_data[*output_index] == NULL) {
        printf("Error: output_data[%d] is NULL!\n", *output_index);
        return;
    }
    //return;
    for (i = 0; i < model->outputs[*output_index].n_elem; i++) {
        data[i]=model->output_data[*output_index][i];
    }
}
void init_onnx_runtime_(void) {
    // Initialize the ONNX Runtime environment
    g_api = OrtGetApiBase()->GetApi(ORT_API_VERSION);
    status = g_api->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "test", &env);
    status = g_api->CreateSessionOptions(&session_options);
    status = g_api->SetIntraOpNumThreads(session_options, 1);
    status = g_api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &memory_info);

    // Initialize sessions for each model
    for (size_t i = 0; i < num_models; i++) {
        status = g_api->CreateSession(env, models[i].model_path, session_options, &sessions[i]);
        if (status != NULL) {
            const char* msg = g_api->GetErrorMessage(status);
            fprintf(stderr, "Failed to run ONNX model: %s\n", msg);
            g_api->ReleaseStatus(status);
        }
    }
}


void call_onnx_(int *model_index) {
    ModelInfo *model = &models[*model_index];
    char* input_names[MAX_INPUTS];
    char* output_names[MAX_OUTPUTS];
    const OrtValue* input_tensors[MAX_INPUTS];
    OrtValue* output_tensors[MAX_OUTPUTS];
    //printf("model num_inputs %d\n",model->num_inputs);
    //printf("model num_outputs %d\n",model->num_outputs);
    for (size_t i = 0; i < model->num_inputs; i++) {
        input_names[i] = (char *)malloc(50 * sizeof(char));
    }
    for (size_t i = 0; i < model->num_outputs; i++) {
        output_names[i] = (char *)malloc(50 * sizeof(char));
    }
    // Prepare input tensors
    for (size_t i = 0; i < model->num_inputs; i++) {
        strcpy(input_names[i], model->inputs[i].name);
        int64_t *shape = (int64_t *)malloc(model->inputs[i].shape_len * sizeof(int64_t));
        for (size_t j = 0; j < model->inputs[i].shape_len; j++) {
            shape[j] = model->inputs[i].shape[j];
        }
        size_t shape_len = model->inputs[i].shape_len;
        size_t tensor_size = 1;
        for (size_t j = 0; j < shape_len; j++) {
            tensor_size *= shape[j];
        }
        status = g_api->CreateTensorWithDataAsOrtValue(
            memory_info, model->input_data[i], tensor_size * sizeof(float),
            shape, shape_len, model->inputs[i].dtype, &input_tensors[i]);
        if (status != NULL) {
                const char* msg = g_api->GetErrorMessage(status);
                fprintf(stderr, "Failed to create input tensor: %s\n", msg);
                g_api->ReleaseStatus(status);}
    }

    // Prepare output tensors
    for (size_t i = 0; i < model->num_outputs; i++) {
        strcpy(output_names[i],model->outputs[i].name);
        int64_t *shape = (int64_t *)malloc(model->outputs[i].shape_len * sizeof(int64_t));
        for (size_t j = 0; j < model->outputs[i].shape_len; j++) {
            shape[j] = model->outputs[i].shape[j];
        }
        //model->outputs[i].shape;
        size_t shape_len = model->outputs[i].shape_len;
        size_t tensor_size = 1;
        for (size_t j = 0; j < shape_len; j++) {
            tensor_size *= shape[j];
        }
        status = g_api->CreateTensorWithDataAsOrtValue(
            memory_info, model->output_data[i], tensor_size * sizeof(float),
            shape, shape_len, model->outputs[i].dtype, &output_tensors[i]);
        if (status != NULL) {
                const char* msg = g_api->GetErrorMessage(status);
                fprintf(stderr, "Failed to create output tensor: %s\n", msg);
                g_api->ReleaseStatus(status);}
    }
    //printf("got here\n");
    //printf("model index: %d\n", *model_index);
    //printf("input name %s\n", input_names[0]);
    //printf("output name %s\n", output_names[0]);
    //printf("%d\n", model->num_inputs);
    //printf("%d\n", model->num_outputs);
    // Run the model
    status = g_api->Run(
        sessions[*model_index], NULL, input_names, input_tensors, model->num_inputs,
        output_names, model->num_outputs, output_tensors);

    if (status != NULL) {
        const char* msg = g_api->GetErrorMessage(status);
        fprintf(stderr, "Failed to run ONNX model: %s\n", msg);
        g_api->ReleaseStatus(status);
    }
    
    // Release resources
    for (size_t i = 0; i < model->num_inputs; i++) {
        g_api->ReleaseValue(input_tensors[i]);
    }
    for (size_t i = 0; i < model->num_outputs; i++) {
        g_api->ReleaseValue(output_tensors[i]);
    }
    for (size_t i = 0; i < model->num_inputs; i++) {
        free(input_names[i]);
    }
    for (size_t i = 0; i < model->num_outputs; i++) {
        free(output_names[i]);
    }
}