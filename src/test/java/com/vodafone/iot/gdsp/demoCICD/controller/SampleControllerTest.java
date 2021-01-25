package com.vodafone.iot.gdsp.demoCICD.controller;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import com.vodafone.iot.gdsp.demoCICD.service.SampleService;

import junit.framework.Assert;

@RunWith(SpringRunner.class)
@SpringBootTest
public class SampleControllerTest {

	@Autowired
	SampleService service;

	@Test
	public void contextLoads() {
	}

	@Test
	public void helloWorldTest() {
		String response = "Hello World";
		String res = service.helloWorld();
		Assert.assertEquals(response, res);

	}

}
